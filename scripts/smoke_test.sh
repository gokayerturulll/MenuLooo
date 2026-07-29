#!/usr/bin/env bash
#
# Smoke test — "image build oluyor mu?" değil, "gerçekten ÇALIŞIYOR mu?" testi.
#
# db → migrate → backend zincirini ayağa kaldırır ve şunları doğrular:
#   1. Backend container'ı healthy duruma geçiyor            (Dockerfile HEALTHCHECK)
#   2. /health 200 + {"status":"ok"} dönüyor
#   3. /metrics Prometheus formatında ve DB havuzu metriklerini içeriyor
#      (→ backend DB'ye gerçekten bağlanmış demektir)
#   4. postgis ve vector uzantıları DB'de gerçekten kurulu
#   5. migrations/ içindeki her .sql dosyası _migrations tablosuna işlenmiş
#   6. Tanımsız endpoint 404 dönüyor (Express router ayakta)
#
# Kullanım:
#   ./scripts/smoke_test.sh                # build et, ayağa kaldır, test et, temizle
#   KEEP_UP=1 ./scripts/smoke_test.sh      # test sonrası container'ları açık bırak
#   SKIP_BUILD=1 ./scripts/smoke_test.sh   # image'lar hazır, yeniden build etme
#
# SKIP_BUILD, CI'ın kullandığı yol. Workflow menulo-backend:ci ve menulo-db:ci
# image'larını zaten build etmiş oluyor; docker-compose.ci.yml da servisleri o
# etiketlere bağlıyor. Böylece smoke test'in doğruladığı image ile Trivy'nin
# tarayıp Docker Hub'a push ettiği image aynı digest oluyor. Bayrak olmadan
# compose ikinci kez build ederdi ve iki build farklı içerik üretebilirdi.
#
# Not: kendi geliştirme ortamınla çakışmasın diye ayrı bir compose projesi
# (menulo-ci) ve dolayısıyla AYRI volume'ler kullanır — mevcut menulo_postgres_data
# verine dokunmaz.

set -euo pipefail

PROJECT="${SMOKE_PROJECT:-menulo-ci}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE=(docker compose -p "$PROJECT" -f "$ROOT/docker-compose.yml" -f "$ROOT/docker-compose.ci.yml")
BASE_URL="${BASE_URL:-http://localhost:3010}"   # port docker-compose.ci.yml'de tanımlı

pass() { echo "  ✅ $1"; }
fail() { echo "  ❌ $1"; exit 1; }

cleanup() {
  local code=$?
  if [ $code -ne 0 ]; then
    echo ""
    echo "──────── Hata: servis log'ları ────────"
    "${COMPOSE[@]}" ps || true
    "${COMPOSE[@]}" logs --no-color --tail=200 || true
  fi
  if [ -z "${KEEP_UP:-}" ]; then
    echo ""
    echo "🧹 Temizlik: container ve volume'ler siliniyor ($PROJECT)"
    "${COMPOSE[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
  fi
  exit $code
}
trap cleanup EXIT

# ── Ayağa kaldır ─────────────────────────────────────────────────────────────
# `up backend` yalnızca backend'in depends_on zincirini çeker: db → migrate →
# seed-embeddings → backend. --wait, backend HEALTHCHECK'i geçene kadar bekler;
# migrate çökerse ya da backend healthy olamazsa bu komut sıfırdan farklı döner.
#
# SKIP_BUILD verildiğinde --build düşürülür: compose, docker-compose.ci.yml'deki
# `image:` etiketlerine bakıp hazır image'ları kullanır. Image gerçekten yoksa
# compose yine de build eder (build: tanımı duruyor), yani bayrak yanlışlıkla
# verilirse test sessizce yanlış şeyi ölçmez, sadece yavaşlar.
#
# Bayraklar tek bir dizide toplanıyor ve dizi HİÇBİR ZAMAN boş kalmıyor: `set -u`
# altında boş bir dizinin "${dizi[@]}" ile genişletilmesi bash 4.4'ten eskisinde
# (macOS'un varsayılan bash 3.2'si dahil) "unbound variable" hatası veriyor.
UP_ARGS=(-d --wait --wait-timeout 180)
if [ -n "${SKIP_BUILD:-}" ]; then
  echo "ℹ️  SKIP_BUILD: hazır image'lar kullanılıyor (menulo-backend:ci, menulo-db:ci)"
else
  UP_ARGS+=(--build)
fi

echo "🚀 Servisler ayağa kaldırılıyor (proje: $PROJECT)"
"${COMPOSE[@]}" up "${UP_ARGS[@]}" backend

echo ""
echo "🔍 Kontroller"

# ── 1. /health ───────────────────────────────────────────────────────────────
health="$(curl -fsS --max-time 10 "$BASE_URL/health")"
echo "$health" | grep -q '"status":"ok"' \
  || fail "/health beklenen gövdeyi dönmedi: $health"
pass "/health → $health"

# ── 2. /metrics ──────────────────────────────────────────────────────────────
metrics="$(curl -fsS --max-time 10 "$BASE_URL/metrics")"
for metric in process_cpu_user_seconds_total db_pool_total_connections socketio_connected_clients; do
  echo "$metrics" | grep -q "^$metric" \
    || fail "/metrics içinde '$metric' yok — Prometheus scrape'i boş dönerdi"
done
pass "/metrics Prometheus formatında ve DB havuzu metriklerini içeriyor"

# ── 3. DB uzantıları ─────────────────────────────────────────────────────────
# postgres major sürümü yükseltilip uzantı paketleri güncellenmezse (dependabot.yml'da
# anlatılan postgres 16→18 senaryosu) migrate zaten burada patlar; bu kontrol
# hatanın nedenini log'da açıkça görünür kılar.
db_user="${DB_USER:-menulo}"
db_name="${DB_NAME:-menulo_db}"
extensions="$("${COMPOSE[@]}" exec -T db psql -U "$db_user" -d "$db_name" -tAc \
  "SELECT extname FROM pg_extension ORDER BY extname")"
for ext in postgis vector; do
  echo "$extensions" | grep -qx "$ext" \
    || fail "'$ext' uzantısı DB'de yok (kurulu olanlar: $(echo "$extensions" | tr '\n' ' '))"
done
pass "postgis + vector uzantıları kurulu"

# ── 4. Migration bütünlüğü ───────────────────────────────────────────────────
expected="$(find "$ROOT/backend/migrations" -maxdepth 1 -name '*.sql' | wc -l | tr -d ' ')"
actual="$("${COMPOSE[@]}" exec -T db psql -U "$db_user" -d "$db_name" -tAc \
  "SELECT count(*) FROM _migrations")"
[ "$expected" = "$actual" ] \
  || fail "migration sayısı uyuşmuyor: dosya=$expected, uygulanan=$actual"
pass "$actual migration'ın tamamı uygulandı"

# ── 5. Router ayakta mı ──────────────────────────────────────────────────────
code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$BASE_URL/api/bilinmeyen-endpoint")"
[ "$code" = "404" ] || fail "tanımsız endpoint 404 yerine $code döndü"
pass "tanımsız endpoint → 404"

echo ""
echo "🎉 Smoke test geçti."
