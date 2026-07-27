// roomController — oda oluşturma, katılma ve restoran destesi testleri.
//
// Kritik davranışlar:
//  • Üyelik guard'ı: odanın üyesi olmayan restoran listesini görememeli.
//  • Deste (deck) cache'i: aynı odadaki HERKES aynı restoranları görmeli —
//    bozulursa oylama sessizce anlamsızlaşır, uygulama hata vermez.
//  • Kategori sanitization: istemciden gelen dizi sınırsız/karışık tipte gelebilir.

jest.mock('../config/db', () => ({ query: jest.fn() }));
// joinRoom içinde lazy require ediliyor — gerçek APN modülü yüklenmesin.
jest.mock('../controllers/notificationController', () => ({
    sendPushToUser:       jest.fn().mockResolvedValue(undefined),
    generateRoomDeepLink: jest.fn(() => 'menulo://room/ABC123'),
}));

const pool = require('../config/db');
const notifications = require('../controllers/notificationController');
const roomController = require('../controllers/roomController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

beforeEach(() => {
    pool.query.mockReset();
    notifications.sendPushToUser.mockClear();
});

// ─── createRoom ─────────────────────────────────────────────────────────────

describe('createRoom', () => {
    // uniquePin() → çakışma yok; INSERT friend_room; INSERT room_member
    function mockHappyPath(overrides = {}) {
        pool.query
            .mockResolvedValueOnce({ rowCount: 0 })                       // PIN boşta
            .mockResolvedValueOnce({ rows: [{
                room_id: 1, qr_code: 'A1B2C3', creator_id: 10,
                name: 'Akşam Yemeği', categories: [], status: 'active',
                created_at: '2026-01-01T00:00:00Z', ...overrides,
            }] })
            .mockResolvedValueOnce({ rowCount: 1 });                      // üye eklendi
    }

    test('400 — oda adı boşsa DB\'ye hiç gidilmez', async () => {
        const res = mockRes();
        await roomController.createRoom({ body: { name: '   ' }, user: { user_id: 10 } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — oda adı string değilse', async () => {
        const res = mockRes();
        await roomController.createRoom({ body: { name: 123 }, user: { user_id: 10 } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
    });

    test('201 — oda oluşur, kurucu otomatik üye yapılır', async () => {
        mockHappyPath();
        const res = mockRes();

        await roomController.createRoom(
            { body: { name: 'Akşam Yemeği' }, user: { user_id: 10 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json.mock.calls[0][0].data.pin_code).toBe('A1B2C3');

        // 3. sorgu kurucuyu room_member'a eklemeli
        const memberCall = pool.query.mock.calls[2];
        expect(memberCall[0]).toContain('INSERT INTO room_member');
        expect(memberCall[1]).toEqual([1, 10]);
    });

    test('201 — üretilen PIN 6 karakter ve büyük harf', async () => {
        mockHappyPath();
        const res = mockRes();

        await roomController.createRoom(
            { body: { name: 'Test' }, user: { user_id: 10 } }, res,
        );

        // INSERT friend_room çağrısının 2. parametresi PIN
        const pin = pool.query.mock.calls[1][1][1];
        expect(pin).toMatch(/^[0-9A-F]{6}$/);
    });

    test('PIN çakışırsa yeniden üretilir', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })   // ilk PIN dolu
            .mockResolvedValueOnce({ rowCount: 0 })   // ikinci PIN boşta
            .mockResolvedValueOnce({ rows: [{ room_id: 1, qr_code: 'X', creator_id: 10 }] })
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await roomController.createRoom(
            { body: { name: 'Test' }, user: { user_id: 10 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(201);
    });

    test('500 — 5 denemede benzersiz PIN bulunamazsa', async () => {
        pool.query.mockResolvedValue({ rowCount: 1 }); // her PIN dolu
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await roomController.createRoom(
            { body: { name: 'Test' }, user: { user_id: 10 } }, res,
        );
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(pool.query).toHaveBeenCalledTimes(5);
    });

    describe('kategori sanitization', () => {
        // INSERT friend_room çağrısındaki categories parametresini döner
        async function categoriesSentToDb(categories) {
            mockHappyPath();
            const res = mockRes();
            await roomController.createRoom(
                { body: { name: 'Test', categories }, user: { user_id: 10 } }, res,
            );
            return pool.query.mock.calls[1][1][3];
        }

        test('string olmayan elemanlar atılır', async () => {
            expect(await categoriesSentToDb(['Pizza', 42, null, { a: 1 }, 'Burger']))
                .toEqual(['Pizza', 'Burger']);
        });

        test('50 karakterden uzun kategoriler atılır', async () => {
            expect(await categoriesSentToDb(['Pizza', 'x'.repeat(51)]))
                .toEqual(['Pizza']);
        });

        test('en fazla 20 kategori kabul edilir', async () => {
            const many = Array.from({ length: 50 }, (_, i) => `kat${i}`);
            expect(await categoriesSentToDb(many)).toHaveLength(20);
        });

        test('categories dizi değilse boş diziye düşer', async () => {
            expect(await categoriesSentToDb('Pizza')).toEqual([]);
        });
    });
});

// ─── getRoomRestaurants ─────────────────────────────────────────────────────

describe('getRoomRestaurants', () => {
    const DECK = [
        { restaurant_id: 1, business_name: 'A' },
        { restaurant_id: 2, business_name: 'B' },
    ];

    afterEach(() => {
        // Modül seviyesindeki cache testler arası sızmasın
        [1, 2, 55, 77, 99].forEach(roomController.clearRoomDeck);
    });

    test('400 — roomId sayı değilse', async () => {
        const res = mockRes();
        await roomController.getRoomRestaurants(
            { params: { roomId: 'abc' }, user: { user_id: 1 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('403 — kullanıcı odanın üyesi değilse restoranları göremez', async () => {
        pool.query.mockResolvedValueOnce({ rowCount: 0 }); // üyelik yok
        const res = mockRes();

        await roomController.getRoomRestaurants(
            { params: { roomId: '55' }, user: { user_id: 1 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // odaya bile bakılmamalı
    });

    test('404 — üye ama oda silinmişse', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })   // üyelik var
            .mockResolvedValueOnce({ rows: [] });     // oda yok
        const res = mockRes();

        await roomController.getRoomRestaurants(
            { params: { roomId: '55' }, user: { user_id: 1 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('cache MISS — ilk istek rastgele deste çeker ve cache\'ler', async () => {
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })
            .mockResolvedValueOnce({ rows: [{ room_id: 77 }] })
            .mockResolvedValueOnce({ rows: DECK });
        const res = mockRes();

        await roomController.getRoomRestaurants(
            { params: { roomId: '77' }, user: { user_id: 1 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(200);
        expect(pool.query.mock.calls[2][0]).toContain('TABLESAMPLE');
        expect(roomController.getRoomDeck(77)).toEqual([1, 2]);
    });

    test('cache HIT — ikinci kullanıcı AYNI restoranları görür', async () => {
        roomController.setRoomDeck(99, [1, 2]);
        pool.query
            .mockResolvedValueOnce({ rowCount: 1 })
            .mockResolvedValueOnce({ rows: [{ room_id: 99 }] })
            .mockResolvedValueOnce({ rows: DECK });
        const res = mockRes();

        await roomController.getRoomRestaurants(
            { params: { roomId: '99' }, user: { user_id: 2 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(200);
        // Rastgele değil, cache'lenmiş ID'lerle sorgulanmalı
        const deckCall = pool.query.mock.calls[2];
        expect(deckCall[0]).not.toContain('TABLESAMPLE');
        expect(deckCall[1]).toEqual([[1, 2]]);
        expect(res.json.mock.calls[0][0].data).toEqual(DECK);
    });

    test('500 — DB hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('relation "restaurant" does not exist'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await roomController.getRoomRestaurants(
            { params: { roomId: '55' }, user: { user_id: 1 } }, res,
        );
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('does not exist');
    });
});

// ─── joinRoom ───────────────────────────────────────────────────────────────

describe('joinRoom', () => {
    const ROOM = {
        room_id: 5, name: 'Akşam', categories: ['Pizza'],
        status: 'active', creator_id: 10,
    };

    test('400 — qr_code yoksa', async () => {
        const res = mockRes();
        await roomController.joinRoom({ body: {}, user: { user_id: 20 } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — PIN hiçbir odayla eşleşmiyorsa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await roomController.joinRoom(
            { body: { qr_code: 'ZZZZZZ' }, user: { user_id: 20 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('409 — oda kapanmışsa katılınamaz', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ ...ROOM, status: 'closed' }] });
        const res = mockRes();

        await roomController.joinRoom(
            { body: { qr_code: 'A1B2C3' }, user: { user_id: 20 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(409);
    });

    test('201 — katılım başarılı ve kurucuya push gider', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [ROOM] })
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await roomController.joinRoom(
            { body: { qr_code: 'A1B2C3' }, user: { user_id: 20 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(201);
        expect(notifications.sendPushToUser).toHaveBeenCalledWith(
            10, expect.objectContaining({ extra: { action: 'member_joined', room_code: 'A1B2C3' } }),
        );
    });

    test('201 — kurucu kendi odasına dönerse kendine push atılmaz', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [ROOM] })
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await roomController.joinRoom(
            { body: { qr_code: 'A1B2C3' }, user: { user_id: 10 } }, res, // user_id === creator_id
        );

        expect(res.status).toHaveBeenCalledWith(201);
        expect(notifications.sendPushToUser).not.toHaveBeenCalled();
    });

    test('individual_preferences objesi JSON string olarak kaydedilir', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [ROOM] })
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await roomController.joinRoom({
            body: { qr_code: 'A1B2C3', individual_preferences: { vegan: true } },
            user: { user_id: 20 },
        }, res);

        expect(pool.query.mock.calls[1][1][2]).toBe('{"vegan":true}');
    });

    test('push gönderimi patlarsa katılım yine de başarılı sayılır', async () => {
        notifications.sendPushToUser.mockRejectedValueOnce(new Error('APNs down'));
        pool.query
            .mockResolvedValueOnce({ rows: [ROOM] })
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await roomController.joinRoom(
            { body: { qr_code: 'A1B2C3' }, user: { user_id: 20 } }, res,
        );

        expect(res.status).toHaveBeenCalledWith(201);
    });
});

// ─── verifyRoomMember (socket join_room guard'ı) ────────────────────────────

describe('verifyRoomMember', () => {
    test('üye ise true', async () => {
        pool.query.mockResolvedValueOnce({ rowCount: 1 });
        await expect(roomController.verifyRoomMember(5, 20)).resolves.toBe(true);
    });

    test('üye değilse false — socket odaya alınmamalı', async () => {
        pool.query.mockResolvedValueOnce({ rowCount: 0 });
        await expect(roomController.verifyRoomMember(5, 999)).resolves.toBe(false);
    });
});

// ─── fetchRestaurantsByCategories (start_voting akışı) ──────────────────────

describe('fetchRestaurantsByCategories', () => {
    const ROWS = [{ restaurant_id: 1 }];

    test('kategori yoksa tüm havuzdan rastgele çeker', async () => {
        pool.query.mockResolvedValueOnce({ rows: ROWS });

        await expect(roomController.fetchRestaurantsByCategories([])).resolves.toEqual(ROWS);
        expect(pool.query).toHaveBeenCalledTimes(1);
        expect(pool.query.mock.calls[0][0]).toContain('TABLESAMPLE');
        expect(pool.query.mock.calls[0][1]).toBeUndefined(); // filtre parametresi yok
    });

    test('kategori varsa filtreli sorgu atılır', async () => {
        pool.query.mockResolvedValueOnce({ rows: ROWS });

        await roomController.fetchRestaurantsByCategories(['Pizza']);

        expect(pool.query.mock.calls[0][0]).toContain('categories &&');
        expect(pool.query.mock.calls[0][1]).toEqual([['Pizza']]);
    });

    test('filtre hiç sonuç vermezse tüm havuza fallback yapılır', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [] })      // filtreli sorgu boş
            .mockResolvedValueOnce({ rows: ROWS });   // fallback

        await expect(roomController.fetchRestaurantsByCategories(['Suşi'])).resolves.toEqual(ROWS);
        expect(pool.query).toHaveBeenCalledTimes(2);
        expect(pool.query.mock.calls[1][0]).not.toContain('categories &&');
    });
});
