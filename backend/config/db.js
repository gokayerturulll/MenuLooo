const { Pool } = require('pg');
const promClient = require('prom-client');
const { register } = require('./metrics');
require('dotenv').config();

const pool = new Pool({
    user:     process.env.DB_USER,
    host:     process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port:     parseInt(process.env.DB_PORT || '5432', 10),
    ssl:      process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    // Bağlantı havuzu limitleri — production'da servis çöküşlerine karşı koruma
    max:                  parseInt(process.env.DB_POOL_MAX || '20', 10),
    idleTimeoutMillis:    30_000,   // 30s boşta kalan bağlantıyı kapat
    connectionTimeoutMillis: 5_000, // 5s içinde bağlanamazsa hata fırlat
    allowExitOnIdle:      false,
});

pool.on('error', (err) => {
    console.error('[DB] Beklenmeyen bağlantı hatası:', err.message);
});

// ─── Prometheus: bağlantı havuzu metrikleri ──────────────────────────────────
// collect() her /metrics isteğinde çalışır, pool'un o anki durumunu okur.
new promClient.Gauge({
    name: 'db_pool_total_connections',
    help: 'Havuzdaki toplam bağlantı sayısı',
    registers: [register],
    collect() { this.set(pool.totalCount); },
});
new promClient.Gauge({
    name: 'db_pool_idle_connections',
    help: 'Havuzda boşta bekleyen bağlantı sayısı',
    registers: [register],
    collect() { this.set(pool.idleCount); },
});
new promClient.Gauge({
    name: 'db_pool_waiting_requests',
    help: 'Bağlantı bekleyen istek sayısı (havuz doluysa artar)',
    registers: [register],
    collect() { this.set(pool.waitingCount); },
});

const connectDB = async () => {
    try {
        const client = await pool.connect();
        console.log(`✅ PostgreSQL Connected: ${process.env.DB_NAME}`);
        client.release();
    } catch (err) {
        console.error('❌ PostgreSQL Connection Error:', err.message);
        process.exit(1);
    }
};

connectDB();

module.exports = pool;
