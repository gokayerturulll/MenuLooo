// MenuBot controller — kritik akış testleri (ask).
// Embedding bug'ı sonrası eklendi: input validation + intent gate + restoran
// doğrulama yollarını izole şekilde doğrular. Groq, Gemini ve DB mock'lanır.

// API key uyarılarını sustur — mock'ladığımız için gerçek key'lere ihtiyaç yok
process.env.GEMINI_API_KEY = 'test-key';
process.env.GROQ_API_KEY   = 'test-key';

// ─── SDK Mock'ları (controller import'undan ÖNCE tanımlı olmalı) ──────────────

const mockGroqCreate = jest.fn();
const mockEmbedContent = jest.fn();

jest.mock('groq-sdk', () => {
    return jest.fn().mockImplementation(() => ({
        chat: { completions: { create: mockGroqCreate } },
    }));
});

jest.mock('@google/generative-ai', () => ({
    GoogleGenerativeAI: jest.fn().mockImplementation(() => ({
        getGenerativeModel: () => ({ embedContent: mockEmbedContent }),
    })),
}));

jest.mock('../config/db', () => ({ query: jest.fn() }));

const pool = require('../config/db');
const menubotController = require('../controllers/menubotController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

// JSON içerikli intent yanıtı üretir
function intentReply(intent, district = null) {
    return {
        choices: [{
            message: { content: JSON.stringify({ intent, district, analiz: 'test' }) },
        }],
    };
}

beforeEach(() => {
    pool.query.mockReset();
    mockGroqCreate.mockReset();
    mockEmbedContent.mockReset();
});

describe('ask — input validation', () => {
    test('400 — boş mesaj', async () => {
        const req = { body: { message: '' }, user: { user_id: 1 } };
        const res = mockRes();
        await menubotController.ask(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
        expect(mockGroqCreate).not.toHaveBeenCalled();
        expect(mockEmbedContent).not.toHaveBeenCalled();
    });

    test('400 — sadece boşluk içeren mesaj', async () => {
        const req = { body: { message: '   \n\t  ' }, user: { user_id: 1 } };
        const res = mockRes();
        await menubotController.ask(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
    });

    test('400 — mesaj string değilse', async () => {
        const req = { body: { message: 12345 }, user: { user_id: 1 } };
        const res = mockRes();
        await menubotController.ask(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
    });

    test('400 — mesaj 1000 karakteri aşarsa', async () => {
        const req = { body: { message: 'a'.repeat(1001) }, user: { user_id: 1 } };
        const res = mockRes();
        await menubotController.ask(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
        expect(mockGroqCreate).not.toHaveBeenCalled();
    });
});

describe('ask — intent gate', () => {
    test('200 — off-topic mesaj kalıplı cevapla geri döner, embedding/search çalıştırılmaz', async () => {
        mockGroqCreate.mockResolvedValueOnce(intentReply('off-topic'));
        // Embedding paralel başlatılır ama off-topic'te sessizce atılır.
        // Yine de mock'u tanımlamamız gerek ki Promise reject olmasın.
        mockEmbedContent.mockResolvedValueOnce({ embedding: { values: [0.1, 0.2] } });

        const req = { body: { message: '2+2 kaç eder?' }, user: { user_id: 1 } };
        const res = mockRes();
        await menubotController.ask(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        const payload = res.json.mock.calls[0][0];
        expect(payload.success).toBe(true);
        expect(payload.data.intent_off_topic).toBe(true);
        expect(payload.data.referenced_items).toEqual([]);
        // Stage 3 (cevap üretimi) çalışmamalı — sadece intent için 1 Groq çağrısı
        expect(mockGroqCreate).toHaveBeenCalledTimes(1);
    });
});

describe('ask — restaurant validation (specific mode)', () => {
    test('404 — restaurantId verildi ama DB\'de yok', async () => {
        mockGroqCreate.mockResolvedValueOnce(intentReply('food'));
        mockEmbedContent.mockResolvedValueOnce({ embedding: { values: [0.1, 0.2] } });
        pool.query.mockResolvedValueOnce({ rows: [] }); // restaurant lookup boş

        const req = {
            body: { message: 'menüden öneri var mı', restaurantId: 9999 },
            user: { user_id: 1 },
        };
        const res = mockRes();
        await menubotController.ask(req, res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(pool.query).toHaveBeenCalledWith(
            expect.stringContaining('FROM restaurant'),
            [9999],
        );
    });
});
