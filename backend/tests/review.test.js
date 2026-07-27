// reviewController — yorum listeleme, ekleme ve işletme yanıtı testleri.
//
// Kritik davranışlar:
//  • Puan doğrulama: 1-5 arası TAM SAYI (istemciden ne gelirse gelsin).
//  • Yanıt yetkisi: yalnızca restoranın gerçek sahibi (owner_id) yanıt yazabilir —
//    başka bir Owner hesabı başkasının restoranına yanıt yazamamalı.
//  • Tek yanıt kuralı: UNIQUE ihlali (23505) 500 değil 409 dönmeli.

jest.mock('../config/db', () => ({ query: jest.fn() }));

const pool = require('../config/db');
const reviewController = require('../controllers/reviewController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

beforeEach(() => {
    pool.query.mockReset();
});

// ─── getRestaurantReviews ───────────────────────────────────────────────────

describe('getRestaurantReviews', () => {
    test.each(['abc', '0', '-3'])('400 — geçersiz restoran ID: "%s"', async (id) => {
        const res = mockRes();
        await reviewController.getRestaurantReviews({ params: { id } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('200 — yorumlar count ile döner', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ review_id: 1 }, { review_id: 2 }] });
        const res = mockRes();

        await reviewController.getRestaurantReviews({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0]).toMatchObject({ success: true, count: 2 });
        expect(pool.query.mock.calls[0][1]).toEqual([7]);
    });

    test('200 — yorumu olmayan restoran boş liste döner (404 değil)', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await reviewController.getRestaurantReviews({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].count).toBe(0);
    });

    test('işletme yanıtı LEFT JOIN ile aynı sorguda çekilir', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await reviewController.getRestaurantReviews({ params: { id: '7' } }, res);

        expect(pool.query.mock.calls[0][0]).toContain('LEFT JOIN review_reply');
    });

    test('500 — DB hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('column r.foo does not exist'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await reviewController.getRestaurantReviews({ params: { id: '7' } }, res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('does not exist');
    });
});

// ─── getUserReviews ─────────────────────────────────────────────────────────

describe('getUserReviews', () => {
    test('401 — oturum bilgisi yoksa', async () => {
        const res = mockRes();
        await reviewController.getUserReviews({}, res);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('200 — yalnızca kendi yorumları sorgulanır', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ review_id: 1 }] });
        const res = mockRes();

        await reviewController.getUserReviews({ user: { user_id: 42 } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(pool.query.mock.calls[0][0]).toContain('WHERE r.user_id = $1');
        expect(pool.query.mock.calls[0][1]).toEqual([42]);
    });
});

// ─── addReview ──────────────────────────────────────────────────────────────

describe('addReview', () => {
    const USER = { user_id: 42 };

    function req(body, id = '7') {
        return { params: { id }, user: USER, body };
    }

    test('400 — geçersiz restoran ID', async () => {
        const res = mockRes();
        await reviewController.addReview(req({ content: 'güzel' }, 'abc'), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('401 — oturum yoksa', async () => {
        const res = mockRes();
        await reviewController.addReview(
            { params: { id: '7' }, body: { content: 'güzel' } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(401);
    });

    test('400 — içerik 2000 karakteri aşarsa', async () => {
        const res = mockRes();
        await reviewController.addReview(req({ content: 'a'.repeat(2001) }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — ne yorum ne puan verilmişse', async () => {
        const res = mockRes();
        await reviewController.addReview(req({ content: '   ' }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toMatch(/en az bir puan/i);
    });

    describe('puan doğrulama', () => {
        test.each([0, 6, -1, 3.5, 'abc', NaN])('400 — geçersiz puan: %p', async (rating) => {
            const res = mockRes();
            await reviewController.addReview(req({ rating_taste: rating }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(pool.query).not.toHaveBeenCalled();
        });

        test.each([1, 3, 5, '4'])('kabul — geçerli puan: %p', async (rating) => {
            pool.query
                .mockResolvedValueOnce({ rowCount: 1 })
                .mockResolvedValueOnce({ rows: [{ review_id: 1 }] });
            const res = mockRes();

            await reviewController.addReview(req({ rating_taste: rating }), res);

            expect(res.status).toHaveBeenCalledWith(201);
            expect(pool.query.mock.calls[1][1][3]).toBe(Number(rating)); // sayıya çevrilmiş
        });

        test('boş/eksik puanlar null olarak kaydedilir', async () => {
            pool.query
                .mockResolvedValueOnce({ rowCount: 1 })
                .mockResolvedValueOnce({ rows: [{ review_id: 1 }] });
            const res = mockRes();

            await reviewController.addReview(req({ content: 'güzel', rating_service: '' }), res);

            const params = pool.query.mock.calls[1][1];
            expect(params[3]).toBeNull(); // taste
            expect(params[4]).toBeNull(); // service
            expect(params[5]).toBeNull(); // attitude
        });
    });

    test('404 — restoran yoksa yorum eklenmez', async () => {
        pool.query.mockResolvedValueOnce({ rowCount: 0 });
        const res = mockRes();

        await reviewController.addReview(req({ content: 'güzel' }), res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(pool.query).toHaveBeenCalledTimes(1); // INSERT çalışmamalı
    });

    test('201 — yorum eklenir, kullanıcı ID body\'den DEĞİL token\'dan alınır', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })
            .mockResolvedValueOnce({ rows: [{ review_id: 100, user_id: 42 }] });
        const res = mockRes();

        // Saldırgan body'de başka bir user_id göndermeye çalışıyor
        await reviewController.addReview(req({ content: 'güzel', user_id: 999 }), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(pool.query.mock.calls[1][1][1]).toBe(42); // token'daki ID kullanıldı
    });

    test('201 — sadece puan verilip yorum yazılmazsa content null kaydedilir', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })
            .mockResolvedValueOnce({ rows: [{ review_id: 1 }] });
        const res = mockRes();

        await reviewController.addReview(req({ rating_taste: 5 }), res);

        expect(pool.query.mock.calls[1][1][2]).toBeNull();
    });

    test('içerik başındaki/sonundaki boşluklar temizlenir', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })
            .mockResolvedValueOnce({ rows: [{ review_id: 1 }] });
        const res = mockRes();

        await reviewController.addReview(req({ content: '  harika  ' }), res);

        expect(pool.query.mock.calls[1][1][2]).toBe('harika');
    });
});

// ─── addReply (işletme yanıtı) ──────────────────────────────────────────────

describe('addReply', () => {
    const OWNER = { user_id: 10 };

    function req(body = { content: 'Teşekkürler!' }, params = { id: '7', reviewId: '100' }) {
        return { params, user: OWNER, body };
    }

    test.each([
        ['restoran ID', { id: 'abc', reviewId: '100' }],
        ['yorum ID',    { id: '7',   reviewId: '0'   }],
    ])('400 — geçersiz %s', async (_label, params) => {
        const res = mockRes();
        await reviewController.addReply(req(undefined, params), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('401 — oturum yoksa', async () => {
        const res = mockRes();
        await reviewController.addReply(
            { params: { id: '7', reviewId: '100' }, body: { content: 'x' } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(401);
    });

    test.each([
        ['boş yanıt', '   '],
        ['1000 karakteri aşan yanıt', 'a'.repeat(1001)],
    ])('400 — %s', async (_label, content) => {
        const res = mockRes();
        await reviewController.addReply(req({ content }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await reviewController.addReply(req(), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('403 — BAŞKA bir işletmenin restoranına yanıt yazılamaz', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 999 }] }); // sahibi başkası
        const res = mockRes();

        await reviewController.addReply(req(), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // INSERT'e hiç gidilmemeli
    });

    test('404 — yorum başka bir restorana aitse', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [] }); // review_id + restaurant_id eşleşmedi
        const res = mockRes();

        await reviewController.addReply(req(), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('201 — sahibi yanıt yazabilir', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ review_id: 100 }] })
            .mockResolvedValueOnce({ rows: [{ reply_id: 1, content: 'Teşekkürler!' }] });
        const res = mockRes();

        await reviewController.addReply(req(), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json.mock.calls[0][0].data.reply_id).toBe(1);
    });

    test('409 — aynı yoruma ikinci yanıt (UNIQUE ihlali 500 değil 409 olmalı)', async () => {
        const uniqueViolation = Object.assign(new Error('duplicate key'), { code: '23505' });
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ review_id: 100 }] })
            .mockRejectedValueOnce(uniqueViolation);
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await reviewController.addReply(req(), res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(409);
        expect(res.status).not.toHaveBeenCalledWith(500);
    });

    test('500 — UNIQUE dışı DB hatası 409\'a dönüşmez', async () => {
        const otherError = Object.assign(new Error('deadlock detected'), { code: '40P01' });
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ review_id: 100 }] })
            .mockRejectedValueOnce(otherError);
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await reviewController.addReply(req(), res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('deadlock');
    });
});
