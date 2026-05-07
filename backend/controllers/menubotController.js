// controllers/menubotController.js
// ============================================================================
// MenuBot — Kurumsal RAG + Guardrail mimarisi (graceful error handling ile)
// ----------------------------------------------------------------------------
// Akış: Stage 1 (Intent) → Stage 2 (Vector Search) → Stage 3 (Grounded Gen)
//
// Her Gemini API çağrısı runGeminiCall() ile sarmalanır:
//   • 429 (kota) → 429 + "yoğunluk var, biraz sonra dene"
//   • 503 / timeout → 503 + "sunuculara ulaşılamıyor"
//   • diğer       → 500 + generic mesaj
// Loglar tek satıra indirgenir; stack trace'ler terminali kirletmez.
// ============================================================================

const pool = require('../config/db');
const { GoogleGenerativeAI } = require('@google/generative-ai');

if (!process.env.GEMINI_API_KEY) {
    console.warn("⚠️  GEMINI_API_KEY tanımlı değil — MenuBot endpoint'i hata dönecek.");
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// ─── Modeller ────────────────────────────────────────────────────────────────

const intentModel = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    // maxOutputTokens 5 → 20: model bazen "EVET"/"HAYIR"'ı tek tokende veremiyor,
    // yarım kelime ("EV", "H") dönüyordu. 20 token rahat fazlasıyla yetiyor.
    generationConfig: { temperature: 0, maxOutputTokens: 20 }
});

const embeddingModel = genAI.getGenerativeModel({ model: 'gemini-embedding-001' });

const answerModel = genAI.getGenerativeModel({
    model: 'gemini-2.5-flash',
    systemInstruction: {
        role: 'system',
        parts: [{
            text:
                "Sen MenuLo'nun uzman, nazik ve profesyonel yemek asistanısın. " +
                "SANA VERİLEN VERİTABANI İÇERİĞİ DIŞINDA BİLGİ UYDURMA. " +
                "Kullanıcıya bütçesi, diyeti veya konumu doğrultusunda en iyi seçenekleri sun " +
                "veya restoran hakkındaki sorularını cevapla. " +
                "Yanıtların samimi, akıcı ve 2-4 cümle olsun; ürün önerirken fiyatlarını mutlaka belirt. " +
                "Asla 'elimde bilgi yok, internete bakayım' gibi cümleler kurma — yalnızca sana verilen menü bilgileriyle konuş. " +

                // Adres / Semt farkındalığı
                "ADRES FARKINDALIĞI: Sana verilen menü bilgilerindeki 'Adres' alanlarını dikkatlice incele. " +
                "Eğer kullanıcı belirli bir semtten (örn. 'Ataşehir', 'Kadıköy', 'Üsküdar', 'Maltepe') bahsediyorsa, " +
                "SADECE o semtte adresi geçen restoranları öner; başka semtlerdeki yerleri bu öneriye dahil etme. " +
                "Eğer sorulan semte ait hiçbir veri yoksa, dürüstçe belirt ve elindeki diğer semtlerden alternatif sun. " +
                "Örnek: 'O semtte şu an bir mekanım yok ama Kadıköy'deki Moda Burger güzel bir seçenek olabilir.' " +
                "Asla bir restoranı yanlış semtte göstermeye çalışma, sahte adres uydurma."
        }]
    },
    generationConfig: { temperature: 0.7 }
});

// ─── Sabitler ────────────────────────────────────────────────────────────────

const TOP_K = 6;
const MAX_MESSAGE_LEN = 1000;
const OFF_TOPIC_RESPONSE =
    "Ben MenuLo'nun gurme asistanıyım. Sadece yemekler, mekanlar ve menüler hakkında yardımcı olabilirim.";

const ERROR_MESSAGES = {
    quota: 'Yapay zeka sistemimiz şu an çok yoğun veya günlük limitine ulaştı. Lütfen kısa bir süre sonra tekrar deneyin.',
    unavailable: 'Yapay zeka sunucularına şu an ulaşılamıyor. Lütfen birazdan tekrar deneyin.',
    unknown: 'Yanıt üretilirken sistemsel bir hata oluştu. Lütfen tekrar deneyin.',
};

// ─── Hata Yönetimi Helper'ları ───────────────────────────────────────────────

/** Gemini SDK hatasından HTTP status code'u çıkarır. */
function extractStatus(err) {
    if (typeof err?.status === 'number') return err.status;
    if (typeof err?.statusCode === 'number') return err.statusCode;
    // Mesaj formatı: "[GoogleGenerativeAI Error]: ... [429 Too Many Requests] ..."
    const match = String(err?.message || '').match(/\b(429|500|502|503|504)\b/);
    return match ? parseInt(match[1], 10) : null;
}

function isTimeoutError(err) {
    const msg = String(err?.message || '').toLowerCase();
    if (msg.includes('timeout') || msg.includes('timed out') || msg.includes('etimedout')) return true;
    return ['ETIMEDOUT', 'ECONNRESET', 'ECONNREFUSED', 'ENETUNREACH'].includes(err?.code);
}

/** Hatayı user-facing kategoriye + mesaja eşler. */
function classifyAIError(err) {
    const status = extractStatus(err);

    if (status === 429) {
        return { category: 'quota',       status: 429, userMessage: ERROR_MESSAGES.quota };
    }
    if (status === 503 || status === 504 || isTimeoutError(err)) {
        return { category: 'unavailable', status: 503, userMessage: ERROR_MESSAGES.unavailable };
    }
    return { category: 'unknown', status: 500, userMessage: ERROR_MESSAGES.unknown };
}

/** Tek satırlık temiz log. Stack trace yutulur. */
function logAIError(stage, err) {
    const status = extractStatus(err) ?? 'no-status';
    const firstLine = String(err?.message || err || 'unknown').split('\n')[0].slice(0, 220);
    const code = err?.code ? ` (${err.code})` : '';
    console.error(`[MenuBot Error] ${stage} · ${status}${code} · ${firstLine}`);
}

/**
 * Bir Gemini call'unu güvenli şekilde çalıştırır.
 * Hata yakalanırsa kısa loglar ve `aiClassified` markup'ı ile re-throw eder.
 */
async function runGeminiCall(stage, fn) {
    try {
        return await fn();
    } catch (err) {
        logAIError(stage, err);
        const cls = classifyAIError(err);
        const wrapped = new Error(cls.userMessage);
        wrapped.aiClassified = cls;
        throw wrapped;
    }
}

// ─── Stage 1: Intent Classification (fail-open) ──────────────────────────────

async function isFoodRelated(message) {
    // Few-shot prompting: model ne üreteceğini örnekler üzerinden öğrenir.
    // Her örnek için sadece "EVET" / "HAYIR" çıktısı bekleniyor — bu pattern
    // sayesinde model kendi yanıtını da aynı formatta verir, boş string
    // veya yarım kelime dönüşleri minimize edilir.
    const prompt =
`Görev: Verilen cümlenin yemek, restoran, menü, tarif veya sipariş ile ilgili olup olmadığını analiz et. SADECE 'EVET' veya 'HAYIR' yaz.

Örnekler:
Cümle: "2+2 kaç eder?"
Cevap: HAYIR

Cümle: "Kadıköy'de burgerci öner"
Cevap: EVET

Cümle: "Bana python kodu yaz"
Cevap: HAYIR

Cümle: "Pizza nerede yenir"
Cevap: EVET

Cümle: "${message.trim()}"
Cevap:`;

    try {
        const result = await intentModel.generateContent(prompt);
        const responseText = result?.response?.text() || '';

        // Gelişmiş temizleme: yanıtı sadece harflere indir, boşluk/noktalama/
        // görünmez Unicode karakterleri (zero-width space, BOM vb.) at.
        // Türkçe karakterler korunur.
        const cleanIntent = responseText
            .replace(/[^a-zA-ZçğıöşüÇĞİıÖŞÜ]/g, '')
            .toUpperCase();

        // Kesin kontrol: tam "EVET" var mı, ya da kesilmiş "EV" tek başına
        // mı geldi (===). "HAYIR"ın hiçbir prefix'i ('H', 'HA', 'HAY', 'HAYI',
        // 'HAYIR') 'EV' alt-string'i içermediği için false-positive yok.
        const isRelated = cleanIntent.includes('EVET') || cleanIntent === 'EV';

        // Debug log'ları
        console.log('Gelen Soru:', message);
        console.log('Intent Modelinin Ham Cevabı:', responseText);
        console.log('Temizlenmiş Cevap:', cleanIntent || '(boş)');
        console.log('Karar:', isRelated ? 'GEÇİŞ ONAYLANDI' : 'REDDEDİLDİ');

        return isRelated;
    } catch (err) {
        // Fail-open: classifier düşerse kullanıcıyı bloke etme, RAG'a düş.
        logAIError('intent-classifier (fail-open)', err);
        return true;
    }
}

// ─── Stage 2: Embedding + Vector Search ──────────────────────────────────────

async function embedQuery(text) {
    const result = await runGeminiCall('embedding', () => embeddingModel.embedContent(text));
    const values = result?.embedding?.values;
    if (!Array.isArray(values) || values.length === 0) {
        // Gemini OK döndü ama vektör boş — generic 500 olarak ele al
        const err = new Error('Soru embedding üretilemedi.');
        err.aiClassified = { category: 'unknown', status: 500, userMessage: ERROR_MESSAGES.unknown };
        throw err;
    }
    return `[${values.join(',')}]`;
}

async function searchSpecificRestaurant(restaurantId, vectorLiteral) {
    const { rows } = await pool.query(`
        SELECT
            mi.item_id, mi.name, mi.description,
            mi.price::float    AS price,
            c.name              AS category,
            r.restaurant_id,
            r.business_name     AS restaurant_name,
            r.address           AS restaurant_address
        FROM menu_item mi
        JOIN category c   ON c.category_id   = mi.category_id
        JOIN menu m       ON m.menu_id       = c.menu_id
        JOIN restaurant r ON r.restaurant_id = m.restaurant_id
        WHERE m.restaurant_id = $1
          AND mi.embedding IS NOT NULL
        ORDER BY mi.embedding <=> $2::vector
        LIMIT $3
    `, [restaurantId, vectorLiteral, TOP_K]);
    return rows;
}

async function searchAllRestaurants(vectorLiteral) {
    const { rows } = await pool.query(`
        SELECT
            mi.item_id, mi.name, mi.description,
            mi.price::float    AS price,
            c.name              AS category,
            r.restaurant_id,
            r.business_name     AS restaurant_name,
            r.address           AS restaurant_address
        FROM menu_item mi
        JOIN category c   ON c.category_id   = mi.category_id
        JOIN menu m       ON m.menu_id       = c.menu_id
        JOIN restaurant r ON r.restaurant_id = m.restaurant_id
        WHERE mi.embedding IS NOT NULL
        ORDER BY mi.embedding <=> $1::vector
        LIMIT $2
    `, [vectorLiteral, TOP_K]);
    return rows;
}

// ─── Stage 3: Grounded Generation ────────────────────────────────────────────

function buildContextBlock(items /* , mode */) {
    if (items.length === 0) {
        return 'Veritabanında ilgili menü öğesi bulunamadı.';
    }
    // Zengin format — modelin adres farkındalığı kazanması için her satırda
    // restoran adı + adres + yemek + fiyat + açıklama açıkça yer alır.
    // Stage 3 (Şef) bu blokta semt eşleştirmesi yapabilsin.
    return items.map((it, i) => {
        const parts = [
            `Restoran: ${it.restaurant_name}`,
            `Adres: ${it.restaurant_address || 'Adres bilgisi yok'}`,
            `Yemek: ${it.name}`,
            `Fiyat: ${it.price} TL`,
        ];
        if (it.category) parts.push(`Kategori: ${it.category}`);
        if (it.description) parts.push(`Açıklama: ${it.description}`);
        return `${i + 1}. ${parts.join(', ')}`;
    }).join('\n');
}

async function generateGroundedAnswer({ message, items, mode, restaurantName }) {
    const contextBlock = buildContextBlock(items, mode);

    const userPrompt = mode === 'specific'
        ? `Restoran: ${restaurantName}\n\n` +
          `İlgili menü öğeleri (alaka sırasına göre):\n${contextBlock}\n\n` +
          `Müşterinin sorusu: "${message.trim()}"`
        : `Genel gurme modu — tüm restoranların menüsünden alaka skorlarına göre çekilen öğeler:\n${contextBlock}\n\n` +
          `Müşterinin sorusu: "${message.trim()}"`;

    const completion = await runGeminiCall(
        'answer-generation',
        () => answerModel.generateContent(userPrompt)
    );
    return (completion?.response?.text() || '').trim();
}

// ─── Endpoint ────────────────────────────────────────────────────────────────

/** POST /api/menubot/ask  body: { restaurantId?, message } */
exports.ask = async (req, res) => {
    try {
        const { restaurantId, message } = req.body;

        // Mesaj validation
        if (typeof message !== 'string' || message.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Boş bir mesaj gönderemezsiniz.' });
        }
        if (message.length > MAX_MESSAGE_LEN) {
            return res.status(400).json({
                success: false,
                message: `Mesaj çok uzun (max ${MAX_MESSAGE_LEN} karakter).`
            });
        }

        // restaurantId opsiyonel: varsa specific, yoksa general mode
        let rid = null;
        if (restaurantId !== undefined && restaurantId !== null) {
            const parsed = typeof restaurantId === 'number'
                ? restaurantId
                : parseInt(restaurantId, 10);
            if (!Number.isNaN(parsed) && parsed > 0) rid = parsed;
        }
        const mode = rid ? 'specific' : 'general';
        let restaurantName = null;

        if (rid) {
            const r = await pool.query(
                'SELECT business_name FROM restaurant WHERE restaurant_id = $1',
                [rid]
            );
            if (r.rows.length === 0) {
                return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
            }
            restaurantName = r.rows[0].business_name;
        }

        // ─ STAGE 1: Intent Gate ────────────────────────────────────────────
        const onTopic = await isFoodRelated(message);
        if (!onTopic) {
            return res.status(200).json({
                success: true,
                data: {
                    answer: OFF_TOPIC_RESPONSE,
                    referenced_items: [],
                    intent_off_topic: true,
                    mode
                }
            });
        }

        // ─ STAGE 2: Vector Search ──────────────────────────────────────────
        const vectorLiteral = await embedQuery(message);
        const items = rid
            ? await searchSpecificRestaurant(rid, vectorLiteral)
            : await searchAllRestaurants(vectorLiteral);

        // ─ STAGE 3: Grounded Generation ────────────────────────────────────
        const answer = await generateGroundedAnswer({
            message, items, mode, restaurantName
        });

        if (!answer) {
            return res.status(502).json({ success: false, message: ERROR_MESSAGES.unknown });
        }

        res.status(200).json({
            success: true,
            data: {
                answer,
                referenced_items: items.map(it => ({
                    item_id: it.item_id,
                    name: it.name,
                    price: it.price,
                    category: it.category,
                    restaurant_id: it.restaurant_id,
                    restaurant_name: it.restaurant_name,
                    restaurant_address: it.restaurant_address
                })),
                intent_off_topic: false,
                mode
            }
        });
    } catch (err) {
        // Stage 2/3 helper'larından gelen sınıflandırılmış hatalar
        if (err?.aiClassified) {
            return res.status(err.aiClassified.status).json({
                success: false,
                message: err.aiClassified.userMessage
            });
        }
        // Beklenmedik hata (DB / kod / vb.) — temiz tek satır log + generic 500
        const firstLine = String(err?.message || err).split('\n')[0].slice(0, 220);
        console.error(`[MenuBot Error] endpoint · 500 · ${firstLine}`);
        return res.status(500).json({ success: false, message: ERROR_MESSAGES.unknown });
    }
};
