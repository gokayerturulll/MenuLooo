// config/database.js
// PostgreSQL bağlantı havuzu (connection pool) yapılandırması.
//
// "Connection Pool" Nedir?
// Her API isteğinde yeni bir veritabanı bağlantısı açmak maliyetlidir.
// Pool, önceden belirli sayıda bağlantıyı hazır tutar ve istekler geldiğinde
// bunları yeniden kullanır. Bu sayede hem hız artar hem kaynak tasarrufu sağlanır.

const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST     || 'localhost',
  port:     parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME     || 'menulo_db',
  user:     process.env.DB_USER     || 'menulo_user',
  password: process.env.DB_PASSWORD || 'menulo_pass_2026',
  ssl:      process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,

  // Havuz ayarları
  max: 20,              // Maksimum eş zamanlı bağlantı sayısı
  idleTimeoutMillis: 30000,   // Boşta kalan bağlantı kaç ms sonra kapansın
  connectionTimeoutMillis: 2000, // Bağlantı kurulamazsa kaç ms beklesin
});

// Bağlantı testi
pool.on('connect', () => {
  if (process.env.NODE_ENV !== 'test') {
    console.log('✅ PostgreSQL bağlantısı kuruldu');
  }
});

pool.on('error', (err) => {
  console.error('❌ PostgreSQL bağlantı hatası:', err.message);
});

/**
 * Tek sorgular için: await query('SELECT * FROM users WHERE id = $1', [id])
 * $1, $2 ... PostgreSQL'in parametre sistemi — SQL injection'ı önler
 */
const query = (text, params) => pool.query(text, params);

/**
 * Transaction için: const client = await getClient()
 * client.query / client.release kullan
 */
const getClient = () => pool.connect();

module.exports = { pool, query, getClient };
