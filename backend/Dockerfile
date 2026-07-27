# ── 1. Aşama (deps): sadece bağımlılıkları kurmak için ───────────────────────
FROM node:26-alpine AS deps

WORKDIR /app
COPY package.json package-lock.json ./

# npm ci (npm install değil): package-lock.json'ı bağlayıcı sayar, yani üretim
# image'ı CI'da test edilenin BİREBİR aynı sürümlerini kurar. Lock ile package.json
# uyuşmazsa sessizce farklı sürüm çekmek yerine build'i kırar.
RUN npm ci --omit=dev

# ── 2. Aşama (runtime): gerçek çalışacak image ────────────────────────────────
FROM node:26-alpine

WORKDIR /app

# 1. aşamada kurulan node_modules'ı kopyala (npm install'ı tekrar çalıştırmaya
# gerek yok, 1. aşamanın build araçları/cache'i bu image'a hiç girmiyor)
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# /app içindeki her şeyi "node" kullanıcısına devret ki root olmadan çalışsın
RUN chown -R node:node /app
USER node

EXPOSE 3000

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
