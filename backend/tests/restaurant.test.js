// restaurantController — keşif sorgusu, profil ve görsel yükleme testleri.
//
// En riskli kısım getAllRestaurants'taki DİNAMİK sorgu kurucusu: place() helper'ı
// parametreyi diziye push edip $N döndürüyor. Placeholder sırası bozulursa filtre
// yanlış değere uygulanır ve bu sessizce yanlış sonuç üretir (hata vermez).
// Bu yüzden hem parametre sırası hem $1..$N bütünlüğü ayrıca doğrulanıyor.

jest.mock('../config/db', () => ({ query: jest.fn() }));
jest.mock('fs/promises', () => ({
    mkdir:     jest.fn().mockResolvedValue(undefined),
    writeFile: jest.fn().mockResolvedValue(undefined),
}));

const pool = require('../config/db');
const fs = require('fs/promises');
const restaurantController = require('../controllers/restaurantController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

const OWNER = { user_id: 10 };

beforeEach(() => {
    pool.query.mockReset();
    pool.query.mockResolvedValue({ rows: [], rowCount: 0 });
    fs.mkdir.mockClear();
    fs.writeFile.mockClear();
});

// getAllRestaurants çağırıp üretilen [sql, params] çiftini döner
async function runSearch(query = {}) {
    const res = mockRes();
    await restaurantController.getAllRestaurants({ query }, res);
    const [sql, params] = pool.query.mock.calls[0];
    return { sql, params, res };
}

// ─── getAllRestaurants ──────────────────────────────────────────────────────

describe('getAllRestaurants — filtresiz', () => {
    test('200 — filtre yoksa WHERE üretilmez ve parametre boştur', async () => {
        const { sql, params, res } = await runSearch();

        expect(res.status).toHaveBeenCalledWith(200);
        expect(sql).not.toContain('WHERE');
        expect(params).toEqual([]);
    });

    test('sonuç 200 satırla sınırlanır', async () => {
        const { sql } = await runSearch();
        expect(sql).toContain('LIMIT 200');
    });

    test('koordinat yoksa distance NULL seçilir', async () => {
        const { sql } = await runSearch();
        expect(sql).toContain('NULL::double precision AS distance_m');
        expect(sql).not.toContain('ST_Distance');
    });
});

describe('getAllRestaurants — konum', () => {
    test('lat+lng verilince mesafe hesaplanır ve parametreler LNG,LAT sırasında gider', async () => {
        const { sql, params } = await runSearch({ lat: '41.0', lng: '29.0' });

        expect(sql).toContain('ST_Distance');
        // PostGIS ST_MakePoint(X=longitude, Y=latitude) — sıra ters olursa
        // İstanbul Somali açıklarına düşer, bu yüzden ayrıca doğrulanıyor.
        expect(params).toEqual([29.0, 41.0]);
    });

    test('sadece lat verilirse konum yok sayılır', async () => {
        const { sql, params } = await runSearch({ lat: '41.0' });

        expect(sql).not.toContain('ST_Distance');
        expect(params).toEqual([]);
    });

    test('geçersiz koordinat (metin) yok sayılır', async () => {
        const { sql } = await runSearch({ lat: 'abc', lng: 'def' });
        expect(sql).not.toContain('ST_Distance');
    });

    test('radius km → metreye çevrilir ve ST_DWithin uygulanır', async () => {
        const { sql, params } = await runSearch({ lat: '41.0', lng: '29.0', radius: '5' });

        expect(sql).toContain('ST_DWithin');
        expect(params).toEqual([29.0, 41.0, 5000]); // 5 km = 5000 m
    });

    test('koordinatsız radius yok sayılır', async () => {
        const { sql, params } = await runSearch({ radius: '5' });

        expect(sql).not.toContain('ST_DWithin');
        expect(params).toEqual([]);
    });

    test('sıfır/negatif radius yok sayılır', async () => {
        const { sql } = await runSearch({ lat: '41.0', lng: '29.0', radius: '0' });
        expect(sql).not.toContain('ST_DWithin');
    });
});

describe('getAllRestaurants — diyet ve kategori filtreleri', () => {
    test('dietary virgülle ayrılır, boşluklar temizlenir', async () => {
        const { sql, params } = await runSearch({ dietary: 'Vegan, Glutensiz' });

        expect(sql).toContain('mit.dietary_tags &&');
        expect(params).toEqual([['Vegan', 'Glutensiz']]);
    });

    test('dietary en fazla 10 etikete sınırlanır', async () => {
        const many = Array.from({ length: 20 }, (_, i) => `tag${i}`).join(',');
        const { params } = await runSearch({ dietary: many });

        expect(params[0]).toHaveLength(10);
    });

    test('boş dietary değeri filtre üretmez', async () => {
        const { sql, params } = await runSearch({ dietary: '' });

        expect(sql).not.toContain('dietary_tags');
        expect(params).toEqual([]);
    });

    test('sadece virgüllerden oluşan dietary filtre üretmez', async () => {
        const { sql } = await runSearch({ dietary: ',,,' });
        expect(sql).not.toContain('dietary_tags');
    });

    test('category restaurant.categories ile eşleştirilir', async () => {
        const { sql, params } = await runSearch({ category: 'Pizza,Burger' });

        expect(sql).toContain('r.categories &&');
        expect(params).toEqual([['Pizza', 'Burger']]);
    });

    test('open_now=true açık olma filtresi ekler', async () => {
        const { sql } = await runSearch({ open_now: 'true' });
        expect(sql).toContain('EXTRACT(DOW FROM NOW())');
    });

    test('open_now=false filtre eklemez', async () => {
        const { sql } = await runSearch({ open_now: 'false' });
        expect(sql).not.toContain('WHERE');
    });
});

describe('getAllRestaurants — placeholder bütünlüğü', () => {
    test('tüm filtreler birlikteyken $1..$N kesintisiz ve params ile aynı sayıda', async () => {
        const { sql, params } = await runSearch({
            lat: '41.0', lng: '29.0', radius: '3',
            dietary: 'Vegan', category: 'Pizza', open_now: 'true',
        });

        // lng, lat, radius(m), dietary[], categories[] → 5 parametre
        expect(params).toEqual([29.0, 41.0, 3000, ['Vegan'], ['Pizza']]);

        // Sorguda geçen placeholder'lar tam olarak $1..$5 olmalı — atlama/tekrar olmamalı
        const used = [...new Set((sql.match(/\$\d+/g) || []).map(p => parseInt(p.slice(1), 10)))]
            .sort((a, b) => a - b);
        expect(used).toEqual([1, 2, 3, 4, 5]);
        expect(Math.max(...used)).toBe(params.length);
    });
});

describe('getAllRestaurants — sıralama', () => {
    test.each([
        ['rating_desc', 'avg_rating DESC'],
        ['price_asc',   'avg_price ASC'],
        ['price_desc',  'avg_price DESC'],
    ])('sort=%s → %s', async (sort, expected) => {
        const { sql } = await runSearch({ sort });
        expect(sql).toContain(`ORDER BY ${expected}`);
    });

    test('sort=distance_asc koordinat varsa mesafeye göre sıralar', async () => {
        const { sql } = await runSearch({ sort: 'distance_asc', lat: '41.0', lng: '29.0' });
        expect(sql).toContain('ORDER BY distance_m ASC');
    });

    test('sort=distance_asc koordinat yoksa puana geri düşer (SQL hatası vermez)', async () => {
        const { sql } = await runSearch({ sort: 'distance_asc' });
        expect(sql).toContain('ORDER BY avg_rating DESC');
    });

    test('bilinmeyen sort değeri varsayılana düşer', async () => {
        const { sql } = await runSearch({ sort: '; DROP TABLE restaurant; --' });
        expect(sql).toContain('ORDER BY avg_rating DESC');
        expect(sql).not.toContain('DROP TABLE');
    });
});

describe('getAllRestaurants — hata', () => {
    test('500 — DB hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('function st_dwithin does not exist'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await restaurantController.getAllRestaurants({ query: {} }, res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('st_dwithin');
    });
});

// ─── getRestaurantById ──────────────────────────────────────────────────────

describe('getRestaurantById', () => {
    test('400 — geçersiz kimlik', async () => {
        const res = mockRes();
        await restaurantController.getRestaurantById({ params: { rid: 'abc' } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await restaurantController.getRestaurantById({ params: { rid: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('200 — detay döner', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ restaurant_id: 7, business_name: 'Test' }] });
        const res = mockRes();

        await restaurantController.getRestaurantById({ params: { rid: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].data.restaurant_id).toBe(7);
    });
});

// ─── updateRestaurant ───────────────────────────────────────────────────────

describe('updateRestaurant', () => {
    function req(body = {}, rid = '7') {
        return { params: { rid }, user: OWNER, body };
    }

    // Sahiplik OK + UPDATE başarılı
    function mockOwned() {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ restaurant_id: 7 }] });
    }

    test('400 — geçersiz kimlik', async () => {
        const res = mockRes();
        await restaurantController.updateRestaurant(req({}, 'abc'), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await restaurantController.updateRestaurant(req(), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('403 — BAŞKA bir işletmenin profili güncellenemez', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 999 }] });
        const res = mockRes();

        await restaurantController.updateRestaurant(req({ business_name: 'Ele Geçirildi' }), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // UPDATE çalışmamalı
    });

    describe('input doğrulama', () => {
        test('400 — 100 karakterden uzun işletme adı', async () => {
            pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 10 }] });
            const res = mockRes();

            await restaurantController.updateRestaurant(req({ business_name: 'a'.repeat(101) }), res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(pool.query).toHaveBeenCalledTimes(1);
        });

        test('400 — 200 karakterden uzun adres', async () => {
            pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 10 }] });
            const res = mockRes();

            await restaurantController.updateRestaurant(req({ address: 'a'.repeat(201) }), res);

            expect(res.status).toHaveBeenCalledWith(400);
        });

        test('400 — 1000 karakterden uzun açıklama', async () => {
            pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 10 }] });
            const res = mockRes();

            await restaurantController.updateRestaurant(req({ description: 'a'.repeat(1001) }), res);

            expect(res.status).toHaveBeenCalledWith(400);
        });

        test.each(['abc', '123', '+90 555 123 45 67 89 01 23 45'])(
            '400 — geçersiz telefon: "%s"', async (phone) => {
                pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 10 }] });
                const res = mockRes();

                await restaurantController.updateRestaurant(req({ phone }), res);

                expect(res.status).toHaveBeenCalledWith(400);
            },
        );

        test.each(['+90 555 123 45 67', '05551234567', '(212) 555-1234'])(
            'kabul — geçerli telefon: "%s"', async (phone) => {
                mockOwned();
                const res = mockRes();

                await restaurantController.updateRestaurant(req({ phone }), res);

                expect(res.status).toHaveBeenCalledWith(200);
            },
        );
    });

    test('200 — koordinatsız güncelleme location_point\'e dokunmaz', async () => {
        mockOwned();
        const res = mockRes();

        await restaurantController.updateRestaurant(req({ business_name: 'Yeni Ad' }), res);

        expect(res.status).toHaveBeenCalledWith(200);
        const [sql, params] = pool.query.mock.calls[1];
        // RETURNING bloğu location_point'i OKUR; burada önemli olan SET'te
        // konuma ATAMA yapılmaması.
        expect(sql).not.toContain('ST_MakePoint');
        expect(params).toHaveLength(8);
        expect(params[7]).toBe(7); // restaurantId
    });

    test('200 — koordinatlı güncellemede LNG,LAT sırası korunur', async () => {
        mockOwned();
        const res = mockRes();

        await restaurantController.updateRestaurant(
            req({ latitude: 41.0, longitude: 29.0 }), res,
        );

        const [sql, params] = pool.query.mock.calls[1];
        expect(sql).toContain('ST_MakePoint($8, $9)');
        expect(params[7]).toBe(29.0); // longitude → X
        expect(params[8]).toBe(41.0); // latitude  → Y
        expect(params[9]).toBe(7);    // restaurantId
    });

    test('koordinat string olarak gelirse konum güncellenmez', async () => {
        mockOwned();
        const res = mockRes();

        await restaurantController.updateRestaurant(
            req({ latitude: '41.0', longitude: '29.0' }), res,
        );

        expect(pool.query.mock.calls[1][0]).not.toContain('ST_MakePoint');
    });

    test('working_hours JSON string\'e çevrilerek kaydedilir', async () => {
        mockOwned();
        const res = mockRes();
        const hours = { open_hour: 9, close_hour: 22, open_days: { Pazartesi: true } };

        await restaurantController.updateRestaurant(req({ working_hours: hours }), res);

        expect(pool.query.mock.calls[1][1][6]).toBe(JSON.stringify(hours));
    });

    test('working_hours gönderilmezse null geçilir (COALESCE korur)', async () => {
        mockOwned();
        const res = mockRes();

        await restaurantController.updateRestaurant(req({ business_name: 'X' }), res);

        expect(pool.query.mock.calls[1][1][6]).toBeNull();
    });
});

// ─── getRestaurantStats ─────────────────────────────────────────────────────

describe('getRestaurantStats', () => {
    test('400 — geçersiz kimlik', async () => {
        const res = mockRes();
        await restaurantController.getRestaurantStats({ params: { id: 'abc' } }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await restaurantController.getRestaurantStats({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('200 — puan ve fiyat aralığı döner', async () => {
        pool.query.mockResolvedValueOnce({
            rows: [{ restaurant_id: 7, avg_rating: 4.5, review_count: 12, price_range: '₺₺' }],
        });
        const res = mockRes();

        await restaurantController.getRestaurantStats({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].data).toMatchObject({ avg_rating: 4.5, price_range: '₺₺' });
    });
});

// ─── uploadRestaurantImage ──────────────────────────────────────────────────

describe('uploadRestaurantImage', () => {
    function file(overrides = {}) {
        return {
            mimetype: 'image/png', size: 2048,
            originalname: 'logo.png', buffer: Buffer.from('x'), ...overrides,
        };
    }

    function req(fileObj, id = '7') {
        return { params: { id }, user: OWNER, file: fileObj };
    }

    test('400 — dosya yoksa', async () => {
        const res = mockRes();
        await restaurantController.uploadRestaurantImage(req(null), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('400 — izin verilmeyen MIME tipi', async () => {
        const res = mockRes();
        await restaurantController.uploadRestaurantImage(
            req(file({ mimetype: 'text/html' })), res,
        );

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — 5 MB üzeri dosya', async () => {
        const res = mockRes();
        await restaurantController.uploadRestaurantImage(
            req(file({ size: 5 * 1024 * 1024 + 1 })), res,
        );

        expect(res.status).toHaveBeenCalledWith(400);
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('403 — BAŞKA bir işletmenin görseli değiştirilemez', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 999 }] });
        const res = mockRes();

        await restaurantController.uploadRestaurantImage(req(file()), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('200 — görsel kaydedilir, dosya adı kullanıcı girdisinden kurulmaz', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ restaurant_id: 7, image_url: '/uploads/restaurants/x.png' }] });
        const res = mockRes();

        await restaurantController.uploadRestaurantImage(
            req(file({ originalname: '../../../etc/shadow' })), res,
        );

        expect(res.status).toHaveBeenCalledWith(200);
        const writtenPath = fs.writeFile.mock.calls[0][0];
        expect(writtenPath).not.toContain('..');
        expect(writtenPath).not.toContain('shadow');
        expect(writtenPath).toMatch(/\/7_[0-9a-f]{16}\.[a-z0-9]+$/);
    });
});

// ─── getRestaurantMenu ──────────────────────────────────────────────────────

describe('getRestaurantMenu', () => {
    test('404 — restoranın menüsü yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await restaurantController.getRestaurantMenu({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('200 — kategoriler ve ürünler gruplanmış döner', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })
            .mockResolvedValueOnce({ rows: [
                { category_id: 1, category_name: 'Ana Yemek', items: [{ item_id: 1, name: 'Pizza' }] },
            ] });
        const res = mockRes();

        await restaurantController.getRestaurantMenu({ params: { id: '7' } }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].data).toMatchObject({
            menu_id: 3, restaurant_id: 7,
        });
        expect(res.json.mock.calls[0][0].data.categories[0].items).toHaveLength(1);
    });

    test('ürünsüz kategori boş dizi ile döner (null değil)', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })
            .mockResolvedValueOnce({ rows: [{ category_id: 1, category_name: 'Tatlı', items: [] }] });
        const res = mockRes();

        await restaurantController.getRestaurantMenu({ params: { id: '7' } }, res);

        // FILTER (WHERE ...) + COALESCE '[]' bu davranışı garanti eder
        expect(pool.query.mock.calls[1][0]).toContain("FILTER (WHERE mi.item_id IS NOT NULL), '[]'");
        expect(res.json.mock.calls[0][0].data.categories[0].items).toEqual([]);
    });

    test('500 — DB hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('column c.foo does not exist'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await restaurantController.getRestaurantMenu({ params: { id: '7' } }, res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('does not exist');
    });
});
