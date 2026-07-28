// userController — profil okuma ve güncelleme testleri.
//
// Kritik davranışlar:
//  • Doğrulama DB'ye gitmeden yapılmalı: geçersiz girdide sorgu hiç açılmamalı.
//  • COALESCE mantığı: gönderilmeyen alan mevcut değerini korumalı, yani
//    parametre olarak null gitmeli. Bozulursa kullanıcı sadece telefonunu
//    güncellemek isterken username'i sessizce silinir.
//  • Guard'lar `!== undefined` ile kurulu — boş string ile hiç gönderilmemiş
//    alanı ayırt etmek testin asıl konusu.

jest.mock('../config/db', () => ({ query: jest.fn() }));

const pool           = require('../config/db');
const userController = require('../controllers/userController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

const PROFIL = {
    user_id: 7, username: 'gokay', email: 'g@menulo.com',
    role: 'Customer', phone_number: '+90 555 111 22 33',
    created_at: '2026-01-01T00:00:00Z',
};

beforeEach(() => {
    pool.query.mockReset();
    jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterEach(() => {
    console.error.mockRestore();
});

// ─── getMe ──────────────────────────────────────────────────────────────────

describe('getMe', () => {
    test('200 — profil döner', async () => {
        pool.query.mockResolvedValueOnce({ rows: [PROFIL] });
        const res = mockRes();

        await userController.getMe({ user: { user_id: 7 } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json).toHaveBeenCalledWith({ success: true, data: PROFIL });
    });

    test('sorgu token\'daki user_id ile parametrelenir', async () => {
        pool.query.mockResolvedValueOnce({ rows: [PROFIL] });

        await userController.getMe({ user: { user_id: 7 } }, mockRes());

        expect(pool.query).toHaveBeenCalledWith(expect.any(String), [7]);
    });

    test('404 — kullanıcı silinmişse', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await userController.getMe({ user: { user_id: 999 } }, res);

        expect(res.status).toHaveBeenCalledWith(404);
        expect(res.json).toHaveBeenCalledWith(
            expect.objectContaining({ success: false })
        );
    });

    test('500 — DB hatası dışarı sızmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('bağlantı koptu'));
        const res = mockRes();

        await userController.getMe({ user: { user_id: 7 } }, res);

        expect(res.status).toHaveBeenCalledWith(500);
        // Hata mesajının kendisi istemciye verilmemeli.
        expect(res.json.mock.calls[0][0].message).not.toMatch(/bağlantı koptu/);
    });
});

// ─── updateMe ───────────────────────────────────────────────────────────────

describe('updateMe', () => {
    const req = (body) => ({ body, user: { user_id: 7 } });

    describe('username doğrulaması', () => {
        test.each([
            ['string değil',   123],
            ['boş string',     ''],
            ['sadece boşluk',  '    '],
            ['51 karakter',    'a'.repeat(51)],
        ])('400 — %s', async (_ad, username) => {
            const res = mockRes();

            await userController.updateMe(req({ username }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(pool.query).not.toHaveBeenCalled();   // DB'ye hiç gidilmedi
        });

        test('50 karakter sınırı dahil — kabul edilir', async () => {
            pool.query.mockResolvedValueOnce({ rows: [PROFIL] });
            const res = mockRes();

            await userController.updateMe(req({ username: 'a'.repeat(50) }), res);

            expect(res.status).toHaveBeenCalledWith(200);
        });

        test('baştaki/sondaki boşluklar kırpılarak kaydedilir', async () => {
            pool.query.mockResolvedValueOnce({ rows: [PROFIL] });

            await userController.updateMe(req({ username: '  gokay  ' }), mockRes());

            expect(pool.query).toHaveBeenCalledWith(
                expect.any(String),
                ['gokay', null, 7]
            );
        });
    });

    describe('telefon doğrulaması', () => {
        test.each([
            ['string değil',      555],
            ['çok kısa',          '123'],
            ['harf içeriyor',     '+90 555 ABC 22 33'],
            ['21 karakter',       '+' + '1'.repeat(21)],
        ])('400 — %s', async (_ad, phone_number) => {
            const res = mockRes();

            await userController.updateMe(req({ phone_number }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(pool.query).not.toHaveBeenCalled();
        });

        test.each([
            ['+90 ile',        '+90 555 111 22 33'],
            ['parantezli',     '(555) 111-2233'],
            ['sadece rakam',   '5551112233'],
        ])('kabul edilir — %s', async (_ad, phone_number) => {
            pool.query.mockResolvedValueOnce({ rows: [PROFIL] });
            const res = mockRes();

            await userController.updateMe(req({ phone_number }), res);

            expect(res.status).toHaveBeenCalledWith(200);
        });

        test('null gönderilebilir — telefonu temizlemek doğrulamayı tetiklemez', async () => {
            pool.query.mockResolvedValueOnce({ rows: [PROFIL] });
            const res = mockRes();

            await userController.updateMe(req({ phone_number: null }), res);

            expect(res.status).toHaveBeenCalledWith(200);
        });
    });

    // COALESCE davranışı: gönderilmeyen alan null gitmeli ki DB mevcut değeri
    // korusun. Buradaki bir regresyon veri KAYBI demek, bu yüzden ayrı test.
    test('sadece telefon gönderildiğinde username parametresi null gider', async () => {
        pool.query.mockResolvedValueOnce({ rows: [PROFIL] });

        await userController.updateMe(req({ phone_number: '5551112233' }), mockRes());

        expect(pool.query).toHaveBeenCalledWith(
            expect.any(String),
            [null, '5551112233', 7]
        );
    });

    test('sadece username gönderildiğinde telefon parametresi null gider', async () => {
        pool.query.mockResolvedValueOnce({ rows: [PROFIL] });

        await userController.updateMe(req({ username: 'yeni' }), mockRes());

        expect(pool.query).toHaveBeenCalledWith(
            expect.any(String),
            ['yeni', null, 7]
        );
    });

    test('boş gövde — her iki parametre de null, sorgu yine de çalışır', async () => {
        pool.query.mockResolvedValueOnce({ rows: [PROFIL] });
        const res = mockRes();

        await userController.updateMe(req({}), res);

        expect(pool.query).toHaveBeenCalledWith(expect.any(String), [null, null, 7]);
        expect(res.status).toHaveBeenCalledWith(200);
    });

    test('200 — güncellenmiş profil döner', async () => {
        const guncel = { ...PROFIL, username: 'yeni' };
        pool.query.mockResolvedValueOnce({ rows: [guncel] });
        const res = mockRes();

        await userController.updateMe(req({ username: 'yeni' }), res);

        expect(res.json).toHaveBeenCalledWith({ success: true, data: guncel });
    });

    test('404 — güncellenecek kullanıcı yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await userController.updateMe(req({ username: 'yeni' }), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('500 — DB hatasında', async () => {
        pool.query.mockRejectedValueOnce(new Error('deadlock'));
        const res = mockRes();

        await userController.updateMe(req({ username: 'yeni' }), res);

        expect(res.status).toHaveBeenCalledWith(500);
    });
});
