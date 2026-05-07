// scripts/seed_embeddings.js
// Tüm menu_item kayıtlarını Gemini gemini-embedding-001 ile 768 boyutlu vektöre
// çevirip pgvector kolonuna yazar (MenuBot AI arama altyapısı için).
//
// Çalıştırma: node backend/scripts/seed_embeddings.js
// Gerekli env: DB_USER, DB_HOST, DB_NAME, DB_PASSWORD, DB_PORT, GEMINI_API_KEY
// Gerekli paketler: pg, dotenv, @google/generative-ai

const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '..', '.env') });

const { Pool } = require('pg');
const { GoogleGenerativeAI } = require('@google/generative-ai');

// ----------------------------------------------------------------------------
// Konfigürasyon
// ----------------------------------------------------------------------------
const EMBEDDING_DIM = 3072;            // gemini-embedding-001 default boyutu
const REQUEST_DELAY_MS = 120;         // Rate-limit'e takılmamak için ufak bekleme
const BATCH_LOG_EVERY = 10;           // Her N üründe bir özet log

const pool = new Pool({
    user: process.env.DB_USER,
    host: process.env.DB_HOST,
    database: process.env.DB_NAME,
    password: process.env.DB_PASSWORD,
    port: process.env.DB_PORT,
});

if (!process.env.GEMINI_API_KEY) {
    console.error('❌ GEMINI_API_KEY ortam değişkeni tanımlı değil. .env dosyasını kontrol edin.');
    process.exit(1);
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const embeddingModel = genAI.getGenerativeModel({ model: 'gemini-embedding-001' });

// ----------------------------------------------------------------------------
// 1) DB hazırlığı: extension + kolon + boyut güncelleme
// ----------------------------------------------------------------------------
async function prepareSchema() {
    console.log('🔧 Şema hazırlanıyor (vector extension + embedding kolonu)…');

    await pool.query('CREATE EXTENSION IF NOT EXISTS vector');

    // Eski boyutta (örn. 1536) veriler ALTER TYPE'ı engelliyor; tamamen drop edip
    // 768 boyutlu olarak yeniden yaratıyoruz. Vektörler bu script tarafından
    // sıfırdan üretileceği için veri kaybı sorun değil.
    await pool.query('ALTER TABLE menu_item DROP COLUMN IF EXISTS embedding');
    await pool.query(`
        ALTER TABLE menu_item
        ADD COLUMN embedding vector(${EMBEDDING_DIM})
    `);

    console.log(`   ↳ menu_item.embedding sıfırlandı → vector(${EMBEDDING_DIM}) hazır.\n`);
}

// ----------------------------------------------------------------------------
// 2) Veri çekme: menu_item ⨝ category ⨝ menu ⨝ restaurant
// ----------------------------------------------------------------------------
async function fetchMenuItemsWithContext() {
    const { rows } = await pool.query(`
        SELECT
            mi.item_id,
            mi.name        AS item_name,
            mi.description AS item_description,
            mi.price::float AS item_price,
            COALESCE(array_to_string(mi.dietary_tags, ', '), '') AS dietary_tags,
            c.name         AS category_name,
            r.business_name AS restaurant_name,
            r.address      AS restaurant_address
        FROM menu_item mi
        JOIN category c   ON c.category_id   = mi.category_id
        JOIN menu m       ON m.menu_id       = c.menu_id
        JOIN restaurant r ON r.restaurant_id = m.restaurant_id
        ORDER BY mi.item_id ASC
    `);
    return rows;
}

// ----------------------------------------------------------------------------
// 3) Anlamlı bağlam metni
// ----------------------------------------------------------------------------
function buildContext(row) {
    const parts = [
        `Restoran: ${row.restaurant_name}`,
        row.restaurant_address ? `Konum: ${row.restaurant_address}` : null,
        `Kategori: ${row.category_name}`,
        `Ürün: ${row.item_name}`,
        row.item_price !== null && row.item_price !== undefined
            ? `Fiyat: ${row.item_price} TL`
            : null,
        row.item_description ? `Açıklama: ${row.item_description}` : null,
        row.dietary_tags ? `Etiketler: ${row.dietary_tags}` : null,
    ].filter(Boolean);

    return parts.join(', ');
}

// ----------------------------------------------------------------------------
// 4) Gemini ile embedding
// ----------------------------------------------------------------------------
async function embed(text) {
    const result = await embeddingModel.embedContent(text);
    const values = result?.embedding?.values;
    if (!Array.isArray(values) || values.length !== EMBEDDING_DIM) {
        throw new Error(
            `Beklenen ${EMBEDDING_DIM} boyutlu vektör alınamadı (alındı: ${values?.length}).`
        );
    }
    return values;
}

// pgvector literal: "[0.1,0.2,...]"
function toVectorLiteral(values) {
    return `[${values.join(',')}]`;
}

async function saveEmbedding(itemId, vector) {
    await pool.query(
        'UPDATE menu_item SET embedding = $1::vector WHERE item_id = $2',
        [toVectorLiteral(vector), itemId]
    );
}

const sleep = (ms) => new Promise(r => setTimeout(r, ms));

// ----------------------------------------------------------------------------
// Ana akış
// ----------------------------------------------------------------------------
async function run() {
    const startedAt = Date.now();

    await prepareSchema();

    const items = await fetchMenuItemsWithContext();
    console.log(`📦 ${items.length} menü öğesi vektörleştirilecek.\n`);

    if (items.length === 0) {
        console.log('ℹ️  İşlenecek ürün bulunamadı.');
        return { success: 0, failed: 0 };
    }

    let success = 0;
    let failed = 0;
    const failures = [];

    for (let i = 0; i < items.length; i++) {
        const row = items[i];
        const label = `[${row.item_id}] ${row.restaurant_name} → ${row.item_name}`;

        try {
            const context = buildContext(row);
            const vector = await embed(context);
            await saveEmbedding(row.item_id, vector);
            success++;
            console.log(`✅ ${label}`);
        } catch (err) {
            failed++;
            failures.push({ itemId: row.item_id, name: row.item_name, error: err.message });
            console.error(`❌ ${label} — ${err.message}`);
        }

        if ((i + 1) % BATCH_LOG_EVERY === 0) {
            const pct = (((i + 1) / items.length) * 100).toFixed(1);
            console.log(`   ⏳ İlerleme: ${i + 1}/${items.length} (%${pct})\n`);
        }

        if (REQUEST_DELAY_MS > 0 && i < items.length - 1) {
            await sleep(REQUEST_DELAY_MS);
        }
    }

    const elapsed = ((Date.now() - startedAt) / 1000).toFixed(1);

    console.log('\n────────────────────────────────────────────');
    console.log(`🎉 Tamamlandı (${elapsed}s)`);
    console.log(`   Başarılı : ${success}`);
    console.log(`   Başarısız: ${failed}`);
    if (failures.length > 0) {
        console.log('\n📋 Hata listesi:');
        for (const f of failures) {
            console.log(`   • [${f.itemId}] ${f.name}: ${f.error}`);
        }
    }
    console.log('────────────────────────────────────────────');

    return { success, failed };
}

// ----------------------------------------------------------------------------
// Entry point
// ----------------------------------------------------------------------------
(async () => {
    try {
        const result = await run();
        await pool.end();
        console.log('🔌 Veritabanı bağlantısı kapatıldı.');
        process.exit(result.failed > 0 ? 1 : 0);
    } catch (err) {
        console.error('💥 Script hatası:', err);
        try { await pool.end(); } catch (_) {}
        process.exit(1);
    }
})();
