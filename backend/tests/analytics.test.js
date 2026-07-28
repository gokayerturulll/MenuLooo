// analyticsController — en çok aranan sorgular endpoint'i.
//
// Kritik davranış: limit istemciden geliyor ve doğrudan SQL'e parametre olarak
// gidiyor. Üst sınır (100) kaldırılırsa tek istekle tüm tablo çekilebilir —
// bu yüzden sınırlama testleri burada asıl konu.

jest.mock('../config/db', () => ({ query: jest.fn() }));

const pool                = require('../config/db');
const analyticsController = require('../controllers/analyticsController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

// Sorguya gerçekte hangi limit gitti?
const gidenLimit = () => pool.query.mock.calls[0][1][0];

const SATIRLAR = [
    { query_text: 'kebap',  search_count: 42, miss_count: 3, last_searched_at: '2026-07-01T10:00:00Z' },
    { query_text: 'pizza',  search_count: 17, miss_count: 0, last_searched_at: '2026-07-02T11:00:00Z' },
];

beforeEach(() => {
    pool.query.mockReset();
    jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
    console.error.mockRestore();
});

describe('getTopSearches', () => {
    test('200 — satırları ve sayıyı döner', async () => {
        pool.query.mockResolvedValueOnce({ rows: SATIRLAR });
        const res = mockRes();

        await analyticsController.getTopSearches({ query: {} }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({
            success: true, count: 2, data: SATIRLAR,
        });
    });

    test('boş sonuçta count 0 olur, hata değil', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await analyticsController.getTopSearches({ query: {} }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({ success: true, count: 0, data: [] });
    });

    describe('limit işleme', () => {
        test('limit verilmezse varsayılan 20', async () => {
            pool.query.mockResolvedValueOnce({ rows: [] });

            await analyticsController.getTopSearches({ query: {} }, mockRes());

            expect(gidenLimit()).toBe(20);
        });

        test('geçerli limit olduğu gibi kullanılır', async () => {
            pool.query.mockResolvedValueOnce({ rows: [] });

            await analyticsController.getTopSearches({ query: { limit: '50' } }, mockRes());

            expect(gidenLimit()).toBe(50);
        });

        // Üst sınır: bu olmadan tek istekle tüm tablo çekilebilir.
        test.each([
            ['101',     100],
            ['999999',  100],
        ])('limit=%s üst sınıra (100) çekilir', async (girdi, beklenen) => {
            pool.query.mockResolvedValueOnce({ rows: [] });

            await analyticsController.getTopSearches({ query: { limit: girdi } }, mockRes());

            expect(gidenLimit()).toBe(beklenen);
        });

        // parseInt başarısız olunca `|| 20` devreye girer.
        test.each([
            ['sayı değil',   'abc'],
            ['boş string',   ''],
            ['sıfır',        '0'],
        ])('geçersiz limit (%s) varsayılana düşer', async (_ad, girdi) => {
            pool.query.mockResolvedValueOnce({ rows: [] });

            await analyticsController.getTopSearches({ query: { limit: girdi } }, mockRes());

            expect(gidenLimit()).toBe(20);
        });

        // "20abc" gibi girdilerde parseInt 20 döner — SQL'e sayı gittiği için
        // enjeksiyon riski yok, ama davranışın kayıt altında olması iyi.
        test('sayıyla başlayan bozuk girdi sayı kısmına indirgenir', async () => {
            pool.query.mockResolvedValueOnce({ rows: [] });

            await analyticsController.getTopSearches({ query: { limit: '30abc' } }, mockRes());

            expect(gidenLimit()).toBe(30);
        });
    });

    test('limit her zaman parametre olarak gider, SQL metnine gömülmez', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });

        await analyticsController.getTopSearches({ query: { limit: '50' } }, mockRes());

        const [sql, params] = pool.query.mock.calls[0];
        expect(sql).toContain('$1');
        expect(sql).not.toContain('50');
        expect(params).toEqual([50]);
    });

    test('500 — DB hatası dışarı sızmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('tablo yok: search_analytics'));
        const res = mockRes();

        await analyticsController.getTopSearches({ query: {} }, res);

        expect(res.status).toHaveBeenCalledWith(500);
        expect(res.json.mock.calls[0][0].message).not.toMatch(/search_analytics/);
    });
});
