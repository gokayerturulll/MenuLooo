# ── Base image ──────────────────────────────────────────────────────────────
FROM node:20-alpine

# ── Çalışma dizini ──────────────────────────────────────────────────────────
WORKDIR /app

# ── Önce sadece dependency dosyalarını kopyala (cache için) ─────────────────
# package.json değişmezse npm install tekrar çalışmaz → hızlı build
COPY package.json package-lock.json ./

# ── Production dependency'leri kur ─────────────────────────────────────────
RUN npm install --omit=dev

# ── Kaynak kodları kopyala ──────────────────────────────────────────────────
COPY . .

# ── Uygulamanın dinlediği port ───────────────────────────────────────────────
EXPOSE 3000

# ── Container başladığında çalışacak komut ──────────────────────────────────
CMD ["node", "server.js"]
