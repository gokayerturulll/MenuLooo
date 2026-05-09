// controllers/menubotController.js
// ============================================================================
// MenuBot — Hibrit RAG Mimarisi (Groq Chat + Gemini Embedding)
// ----------------------------------------------------------------------------
// Stage 1 — Intent Gate          → Groq llama-3.1-8b-instant (JSON, Decision-First)
// Stage 2 — Embedding + Search   → Gemini gemini-embedding-001 + pgvector
// Stage 3 — Grounded Generation  → Groq llama-3.3-70b-versatile (adres farkındalığı)
//
// Neden hibrit?
//   • Gemini chat tarafında 503/429 sıklığı RAG akışını sürekli kesiyordu.
//   • Groq Llama kotaları çok daha geniş + latency düşük.
//   • Embedding tarafında DB'deki 3072d vektörler korunsun diye Gemini kalıyor;
//     boyut değiştirmek tüm tabloyu yeniden seed etmek demektir.
//
// NOT: Talep edilen 'text-embedding-004' modeli artık 768d üretiyor; mevcut DB
// 3072d (gemini-embedding-001 ile seed edilmiş) olduğu için aynı modeli koruduk.
// İleride 768d'ye geçilecekse seed_embeddings.js'in tekrar çalıştırılması gerekir.
// ============================================================================

const pool = require('../config/db');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const Groq = require('groq-sdk');

if (!process.env.GEMINI_API_KEY) {
    console.warn("⚠️  GEMINI_API_KEY tanımlı değil — embedding stage başarısız olacak.");
}
if (!process.env.GROQ_API_KEY) {
    console.warn("⚠️  GROQ_API_KEY tanımlı değil — intent ve generation stage başarısız olacak.");
}

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');
const embeddingModel = genAI.getGenerativeModel({ model: 'gemini-embedding-001' });

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

// ─── Sabitler ────────────────────────────────────────────────────────────────

/** Prompt şablonlarına gömülecek mesajlardan kontrol karakterlerini ve tırnak işaretlerini temizler. */
function sanitizeForPrompt(text) {
    return text
        .replace(/[\x00-\x1F\x7F]/g, ' ') // kontrol karakterleri
        .replace(/"/g, '\\"')               // çift tırnak escape
        .replace(/`/g, "'");               // backtick → single quote
}

const INTENT_MODEL = 'llama-3.1-8b-instant';
const ANSWER_MODEL = 'llama-3.3-70b-versatile';

const TOP_K = 6;
const MAX_MESSAGE_LEN = 1000;
const OFF_TOPIC_RESPONSE =
    "Ben MenuLo'nun gurme asistanıyım. Sadece yemekler, mekanlar ve menüler hakkında yardımcı olabilirim.";

const ERROR_MESSAGES = {
    quota: 'Yapay zeka sistemimiz şu an çok yoğun veya günlük limitine ulaştı. Lütfen kısa bir süre sonra tekrar deneyin.',
    unavailable: 'Yapay zeka sunucularına şu an ulaşılamıyor. Lütfen birazdan tekrar deneyin.',
    unknown: 'Yanıt üretilirken sistemsel bir hata oluştu. Lütfen tekrar deneyin.',
};

const ANSWER_SYSTEM_PROMPT =
    "Sen MenuLo'nun uzman, nazik ve profesyonel yemek asistanısın. " +
    "SANA VERİLEN VERİTABANI İÇERİĞİ DIŞINDA BİLGİ UYDURMA. " +
    "Kullanıcıya bütçesi, diyeti veya konumu doğrultusunda en iyi seçenekleri sun " +
    "veya restoran hakkındaki sorularını cevapla. " +
    "Yanıtların samimi, akıcı ve 2-4 cümle olsun; ürün önerirken fiyatlarını mutlaka belirt. " +
    "Asla 'elimde bilgi yok, internete bakayım' gibi cümleler kurma — yalnızca sana verilen menü bilgileriyle konuş. " +
    "ADRES FARKINDALIĞI: Sana verilen menü bilgilerindeki 'Adres' alanlarını dikkatlice incele. " +
    "Eğer kullanıcı belirli bir semtten (örn. 'Ataşehir', 'Kadıköy', 'Üsküdar', 'Maltepe') bahsediyorsa, " +
    "SADECE o semtte adresi geçen restoranları öner; başka semtlerdeki yerleri bu öneriye dahil etme. " +
    "Eğer sorulan semte ait hiçbir veri yoksa, dürüstçe belirt ve elindeki diğer semtlerden alternatif sun. " +
    "Örnek: 'Şu an o bölgede mekanım yok ama Kadıköy'deki Moda Burger güzel bir seçenek olabilir.' " +
    "Asla bir restoranı yanlış semtte göstermeye çalışma, sahte adres uydurma. " +
    "CHIT-CHAT KURALI: Eğer kullanıcının mesajı sadece 'Selam', 'Merhaba', 'Nasılsın', 'Teşekkürler' gibi kısa bir nezaket veya sohbet (chit-chat) ifadesiyse, SANA VERİLEN VERİTABANI İÇERİĞİNİ (CONTEXT) TAMAMEN GÖRMEZDEN GEL. Kesinlikle mekan veya yemek tavsiyesinde bulunma. Sadece Menulo'nun gurme asistanı olarak kibarca karşılık ver ve 'Bugün canın ne yemek istiyor?' veya 'Sana hangi bölgeden mekan önermemi istersin?' diyerek sohbeti başlat.";

// ─── Hata Yönetimi Helper'ları ───────────────────────────────────────────────

function extractStatus(err) {
    if (typeof err?.status === 'number') return err.status;
    if (typeof err?.statusCode === 'number') return err.statusCode;
    if (typeof err?.response?.status === 'number') return err.response.status;
    const match = String(err?.message || '').match(/\b(429|500|502|503|504)\b/);
    return match ? parseInt(match[1], 10) : null;
}

function isTimeoutError(err) {
    const msg = String(err?.message || '').toLowerCase();
    if (msg.includes('timeout') || msg.includes('timed out') || msg.includes('etimedout')) return true;
    return ['ETIMEDOUT', 'ECONNRESET', 'ECONNREFUSED', 'ENETUNREACH'].includes(err?.code);
}

function classifyAIError(err) {
    const status = extractStatus(err);
    if (status === 429) {
        return { category: 'quota', status: 429, userMessage: ERROR_MESSAGES.quota };
    }
    if (status === 503 || status === 504 || isTimeoutError(err)) {
        return { category: 'unavailable', status: 503, userMessage: ERROR_MESSAGES.unavailable };
    }
    return { category: 'unknown', status: 500, userMessage: ERROR_MESSAGES.unknown };
}

function logAIError(stage, err) {
    const status = extractStatus(err) ?? 'no-status';
    const firstLine = String(err?.message || err || 'unknown').split('\n')[0].slice(0, 220);
    const code = err?.code ? ` (${err.code})` : '';
    console.error(`[MenuBot Error] ${stage} · ${status}${code} · ${firstLine}`);
}

async function runAICall(stage, fn) {
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

// ─── Stage 1: Intent Classification (Groq, Decision-First JSON, fail-open) ──

async function isFoodRelated(message) {
    const systemPrompt =
        "Sen bir MenuLo Gurme Asistanı'nın kapı görevlisisin. MenuLo bir RESTORAN ve MENÜ " +
        "tavsiye uygulamasıdır; bu yüzden kullanıcının cümleleri çoğunlukla yemek bağlamındadır. " +
        "Verilen cümlenin yemek, restoran, menü, tarif, içecek, sipariş veya bu sohbetin doğal " +
        "akışı ile ilgili olup olmadığına karar verirsin. " +
        "ÇIKTI olarak SADECE şu yapıda bir JSON döndür (Decision-First — önce karar, sonra analiz): " +
        '{ "karar": "EVET" veya "HAYIR", "analiz": "Kısa Türkçe gerekçe" } ' +
        "Başka hiçbir metin, açıklama veya markdown ekleme. " +

        // Nezaket / sohbet ifadeleri istisnası
        "ÖNEMLİ İSTİSNA 1 (Nezaket): Kullanıcının 'Selam', 'Merhaba', 'Günaydın', 'İyi akşamlar', " +
        "'Teşekkürler', 'Eline sağlık', 'Sağ ol', 'Tamam', 'Anladım' gibi temel sohbet " +
        "başlatıcı (greetings) veya bitirici nezaket ifadelerini DOĞRUDAN REDDETME. " +
        "Bunları doğal sohbet akışının bir parçası kabul et ve karar alanına 'EVET' yazarak " +
        "geçişlerine izin ver. Yemek asistanı da bir insan gibi selamlaşmalı, teşekkürlere " +
        "kibarca karşılık verebilmelidir. " +

        // Lokasyon ve takip cümlesi varsayımı
        "ÖNEMLİ İSTİSNA 2 (Gurme Uygulaması Varsayımı): MenuLo bir restoran asistanı olduğu için, " +
        "kullanıcı 'Bostancı'da nereler var?', 'Şurada ne var?', 'Yakında bir şey var mı?' gibi " +
        "ucu açık LOKASYON sorularını sorduğunda, bunun bir RESTORAN/MEKAN arayışı olduğunu " +
        "VARSAY ve EVET dön. " +
        "Ayrıca 'Kadıköy'de olmasına gerek yok', 'Fark etmez', 'Başka yer de olur', " +
        "'Daha ucuzu var mı', 'Başka önerin var mı' gibi önceki bir sohbetin DEVAMI niteliğindeki " +
        "(follow-up) kısa cümleleri doğrudan yemek sohbeti kabul et ve KESİNLİKLE REDDETME — " +
        "her zaman EVET dön. Bu kısa cümleler bağlamdan kopuk gibi görünse bile MenuLo akışında " +
        "her zaman bir restoran tavsiyesinin devamıdır.";

    const fewShotExamples = [
        { user: '2+2 kaç eder?',                        out: { karar: 'HAYIR', analiz: 'Matematik sorusu, yemekle ilgisi yok.' } },
        { user: 'Kadıköy\'de burgerci öner',            out: { karar: 'EVET',  analiz: 'Kullanıcı semt bazlı burger restoranı arıyor.' } },
        { user: 'Bana python kodu yaz',                 out: { karar: 'HAYIR', analiz: 'Kod yazma talebi, gastronomi dışı.' } },
        { user: 'Anadolu yakasında tatlı kahve nerede', out: { karar: 'EVET',  analiz: 'Konum bazlı kafe/tatlı tavsiyesi sorusu.' } },
        { user: 'Vegan menü var mı acaba',              out: { karar: 'EVET',  analiz: 'Diyet bazlı menü filtreleme talebi.' } },
        { user: 'Merhaba',                              out: { karar: 'EVET',  analiz: 'Kullanıcı selam veriyor, sohbet başlatmak için izin verilmeli.' } },
        { user: 'Teşekkür ederim çok yardımcı oldun',   out: { karar: 'EVET',  analiz: 'Kullanıcı teşekkür ediyor, nezaket ifadesi, izin verilmeli.' } },
        { user: 'Kadıköyde olmasına gerek yok',         out: { karar: 'EVET',  analiz: 'Lokasyon tercihini değiştiren bir takip cümlesi, sohbet devamı.' } },
        { user: 'Bostancıda nereler var',               out: { karar: 'EVET',  analiz: 'Bir yemek uygulamasında semt soruluyorsa, restoran soruluyordur.' } },
        { user: 'Fark etmez orası da olur',             out: { karar: 'EVET',  analiz: 'Önceki bir yemek tavsiyesine onay veren takip cümlesi.' } },
    ];

    const fewShotText = fewShotExamples
        .map(ex => `Cümle: "${ex.user}"\nCevap: ${JSON.stringify(ex.out)}`)
        .join('\n\n');

    const userPrompt =
        `Aşağıdaki örneklere göre, en sondaki cümlenin yemekle ilgili olup olmadığına karar ver.\n\n` +
        `${fewShotText}\n\n` +
        `Cümle: "${sanitizeForPrompt(message.trim())}"\nCevap:`;

    try {
        const completion = await groq.chat.completions.create({
            model: INTENT_MODEL,
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user',   content: userPrompt }
            ],
            response_format: { type: 'json_object' },
            temperature: 0.1,
            max_tokens: 200,
        });

        const responseText = completion?.choices?.[0]?.message?.content || '';
        let isRelated = false;
        let analiz = null;
        let karar = null;
        let parseStatus = 'parsed';

        try {
            const parsed = JSON.parse(responseText);
            karar = String(parsed?.karar ?? '').toUpperCase().trim();
            analiz = parsed?.analiz ?? null;
            isRelated = karar.includes('EVET');
        } catch (jsonErr) {
            // Truncation handling — JSON yarım kesilmiş olabilir.
            // Regex ile kelime aramıyoruz; JSON YAPISI'nı yakalıyoruz:
            //   "karar": "EVET" / "karar":"EVET" / "karar"  :  "evet"
            parseStatus = 'truncated';
            const yesPattern = /"karar"\s*:\s*"\s*EVET\s*"/i;
            const noPattern  = /"karar"\s*:\s*"\s*HAYIR\s*"/i;

            if (yesPattern.test(responseText)) {
                isRelated = true;
                karar = 'EVET (truncated-recovery)';
            } else if (noPattern.test(responseText)) {
                isRelated = false;
                karar = 'HAYIR (truncated-recovery)';
            } else {
                // JSON yapısı bile bulunamadı — fail-open
                isRelated = true;
                karar = '(yapı yakalanamadı, fail-open)';
                parseStatus = 'unrecoverable';
            }
        }

        // ── Debug log ──
        console.log('Gelen Soru:', message);
        console.log('Intent (Groq) Ham Cevap:', responseText);
        console.log('Parse Durumu:', parseStatus);
        if (analiz) console.log('Analiz:', analiz);
        console.log('Karar:', karar || '(yok)');
        console.log('Final Karar:', isRelated ? 'GEÇİŞ ONAYLANDI' : 'REDDEDİLDİ');

        return isRelated;
    } catch (err) {
        // Fail-open: Groq tamamen çökse bile guard mesajı yapıştırma — RAG'a düş.
        logAIError('intent-classifier (fail-open)', err);
        return true;
    }
}

// ─── Stage 2: Embedding + Vector Search (Gemini + pgvector) ─────────────────

async function embedQuery(text) {
    const result = await runAICall('embedding', () => embeddingModel.embedContent(text));
    const values = result?.embedding?.values;
    if (!Array.isArray(values) || values.length === 0) {
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

// ─── Stage 3: Grounded Generation (Groq llama-3.3-70b-versatile) ────────────

function buildContextBlock(items) {
    if (items.length === 0) {
        return 'Veritabanında ilgili menü öğesi bulunamadı.';
    }
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
    const contextBlock = buildContextBlock(items);

    const safeMessage = sanitizeForPrompt(message.trim());
    const userPrompt = mode === 'specific'
        ? `Restoran: ${restaurantName}\n\n` +
          `İlgili menü öğeleri (alaka sırasına göre):\n${contextBlock}\n\n` +
          `Müşterinin sorusu: "${safeMessage}"`
        : `Genel gurme modu — tüm restoranların menüsünden alaka skorlarına göre çekilen öğeler:\n${contextBlock}\n\n` +
          `Müşterinin sorusu: "${safeMessage}"`;

    const completion = await runAICall(
        'answer-generation',
        () => groq.chat.completions.create({
            model: ANSWER_MODEL,
            messages: [
                { role: 'system', content: ANSWER_SYSTEM_PROMPT },
                { role: 'user',   content: userPrompt }
            ],
            temperature: 0.7,
            max_tokens: 600,
        })
    );

    return (completion?.choices?.[0]?.message?.content || '').trim();
}

// ─── Endpoint ────────────────────────────────────────────────────────────────

/** POST /api/menubot/ask  body: { restaurantId?, message } */
exports.ask = async (req, res) => {
    try {
        const { restaurantId, message } = req.body;

        if (typeof message !== 'string' || message.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Boş bir mesaj gönderemezsiniz.' });
        }
        if (message.length > MAX_MESSAGE_LEN) {
            return res.status(400).json({
                success: false,
                message: `Mesaj çok uzun (max ${MAX_MESSAGE_LEN} karakter).`
            });
        }

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

        // ─ STAGE 1: Intent Gate (fail-open) ────────────────────────────────
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

        // ─ STAGE 3: Grounded Generation (Groq Llama 3.3 70B) ───────────────
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
        if (err?.aiClassified) {
            return res.status(err.aiClassified.status).json({
                success: false,
                message: err.aiClassified.userMessage
            });
        }
        const firstLine = String(err?.message || err).split('\n')[0].slice(0, 220);
        console.error(`[MenuBot Error] endpoint · 500 · ${firstLine}`);
        return res.status(500).json({ success: false, message: ERROR_MESSAGES.unknown });
    }
};
