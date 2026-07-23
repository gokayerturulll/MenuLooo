'use strict';

const fs   = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config();

// ── DB bağlantısı ────────────────────────────────────────────────────────────
const pool = new Pool({
  user:     process.env.DB_USER,
  host:     process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port:     parseInt(process.env.DB_PORT || '5432', 10),
  ssl:      process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

// ── Migration geçmişi tablosu ────────────────────────────────────────────────
const INIT_SQL = `
  CREATE TABLE IF NOT EXISTS _migrations (
    id         SERIAL PRIMARY KEY,
    filename   TEXT NOT NULL UNIQUE,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
`;

async function run() {
  const client = await pool.connect();
  try {
    // Geçmiş tablosunu oluştur (yoksa)
    await client.query(INIT_SQL);

    // Daha önce çalışan migration'ları al
    const { rows } = await client.query('SELECT filename FROM _migrations ORDER BY filename');
    const applied = new Set(rows.map(r => r.filename));

    // migrations/ klasöründeki .sql dosyalarını sıralı al
    const dir      = __dirname;
    const sqlFiles = fs
      .readdirSync(dir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    let count = 0;
    for (const file of sqlFiles) {
      if (applied.has(file)) {
        console.log(`⏭  Skipped (already applied): ${file}`);
        continue;
      }

      const sql = fs.readFileSync(path.join(dir, file), 'utf8');
      console.log(`⚙️  Applying: ${file} ...`);
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO _migrations (filename) VALUES ($1)', [file]);
        await client.query('COMMIT');
        console.log(`✅ Applied: ${file}`);
        count++;
      } catch (err) {
        await client.query('ROLLBACK');
        throw new Error(`❌ Failed on ${file}: ${err.message}`);
      }
    }

    if (count === 0) {
      console.log('✨ All migrations already applied — nothing to do.');
    } else {
      console.log(`\n🎉 Done! ${count} migration(s) applied.`);
    }
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch(err => {
  console.error(err.message);
  process.exit(1);
});
