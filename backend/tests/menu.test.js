// menuController — işletme menü CRUD ve fotoğraf yükleme testleri.
//
// Kritik davranışlar:
//  • Sahiplik guard'ı: ownerOnly rolü geçirir ama BAŞKA bir işletmenin menüsüne
//    dokunmayı engelleyen tek şey buradaki owner_id karşılaştırması.
//  • Fiyat/ad/kategori doğrulama: iOS'tan gelen değerler DB'ye ulaşmadan elenmeli.
//  • Fotoğraf yükleme: MIME allowlist, boyut sınırı ve dosya adının
//    kullanıcıdan gelen isimle ASLA kurulmaması (path traversal).

jest.mock('../config/db', () => ({ query: jest.fn() }));
jest.mock('fs/promises', () => ({
    mkdir:     jest.fn().mockResolvedValue(undefined),
    writeFile: jest.fn().mockResolvedValue(undefined),
}));

const pool = require('../config/db');
const fs = require('fs/promises');
const menuController = require('../controllers/menuController');

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

const OWNER = { user_id: 10 };

// locateItem() tek sorguyla ürün + sahip bilgisini döner
function locatedItem(overrides = {}) {
    return { rows: [{
        item_id: 5, restaurant_id: 7, owner_id: 10, menu_id: 3, category_id: 2, ...overrides,
    }] };
}

beforeEach(() => {
    pool.query.mockReset();
    fs.mkdir.mockClear();
    fs.writeFile.mockClear();
});

// ─── getOwnerMenuItems ──────────────────────────────────────────────────────

describe('getOwnerMenuItems', () => {
    test('400 — geçersiz restoran kimliği', async () => {
        const res = mockRes();
        await menuController.getOwnerMenuItems({ params: { rid: 'abc' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await menuController.getOwnerMenuItems({ params: { rid: '7' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('403 — BAŞKA bir işletmenin menüsü görüntülenemez', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 999 }] });
        const res = mockRes();

        await menuController.getOwnerMenuItems({ params: { rid: '7' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // menü sorgusuna hiç gidilmemeli
    });

    test('200 — ürünler iOS şekline dönüştürülür', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{
                item_id: 1, name: 'Pizza', price: '89.90', description: null,
                category: 'Ana Yemek', is_green_menu: null, is_available: true, image_url: null,
            }] });
        const res = mockRes();

        await menuController.getOwnerMenuItems({ params: { rid: '7' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].data[0]).toEqual({
            item_id: 1, name: 'Pizza',
            price: 89.9,              // string → number
            description: null, category: 'Ana Yemek',
            is_green_menu: false,     // null → false
            is_available: true,
            image_url: null,
        });
    });

    test('200 — price null ise 0 olarak döner (iOS decode hatası olmasın)', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ item_id: 1, name: 'X', price: null }] });
        const res = mockRes();

        await menuController.getOwnerMenuItems({ params: { rid: '7' }, user: OWNER }, res);

        expect(res.json.mock.calls[0][0].data[0].price).toBe(0);
    });
});

// ─── createMenuItem ─────────────────────────────────────────────────────────

describe('createMenuItem', () => {
    function req(body, rid = '7') {
        return { params: { rid }, user: OWNER, body };
    }

    const VALID = { name: 'Pizza', price: 89.9, category: 'Ana Yemek' };

    test('400 — geçersiz restoran kimliği', async () => {
        const res = mockRes();
        await menuController.createMenuItem(req(VALID, 'abc'), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test.each([
        ['name eksik',     { price: 10, category: 'X' }],
        ['price eksik',    { name: 'A', category: 'X' }],
        ['price null',     { name: 'A', price: null, category: 'X' }],
        ['category eksik', { name: 'A', price: 10 }],
    ])('400 — zorunlu alan: %s', async (_label, body) => {
        const res = mockRes();
        await menuController.createMenuItem(req(body), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test.each([
        ['negatif fiyat',     -1],
        ['üst sınır aşımı',   100000],
        ['sayı olmayan',      'bedava'],
    ])('400 — %s', async (_label, price) => {
        const res = mockRes();
        await menuController.createMenuItem(req({ ...VALID, price }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(res.json.mock.calls[0][0].message).toMatch(/fiyat/i);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — 255 karakterden uzun ürün adı', async () => {
        const res = mockRes();
        await menuController.createMenuItem(req({ ...VALID, name: 'a'.repeat(256) }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — 100 karakterden uzun kategori', async () => {
        const res = mockRes();
        await menuController.createMenuItem(req({ ...VALID, category: 'a'.repeat(101) }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('403 — BAŞKA bir işletmenin restoranına ürün eklenemez', async () => {
        pool.query.mockResolvedValueOnce({ rows: [{ owner_id: 999 }] });
        const res = mockRes();

        await menuController.createMenuItem(req(VALID), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // INSERT'e gidilmemeli
    });

    test('404 — restoran yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await menuController.createMenuItem(req(VALID), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('201 — mevcut menü + mevcut kategori ile ürün eklenir', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })   // sahiplik
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })     // menü var
            .mockResolvedValueOnce({ rows: [{ category_id: 2 }] }) // kategori var
            .mockResolvedValueOnce({ rows: [{
                item_id: 50, name: 'Pizza', price: 89.9, is_available: true, category: 'Ana Yemek',
            }] });
        const res = mockRes();

        await menuController.createMenuItem(req(VALID), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(res.json.mock.calls[0][0].data.item_id).toBe(50);
        expect(pool.query).toHaveBeenCalledTimes(4); // hiçbir şey oluşturulmadı
    });

    test('201 — menü yoksa lazy oluşturulur', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [] })                    // menü YOK
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })      // INSERT menu
            .mockResolvedValueOnce({ rows: [{ category_id: 2 }] })
            .mockResolvedValueOnce({ rows: [{ item_id: 50, name: 'Pizza', price: 89.9 }] });
        const res = mockRes();

        await menuController.createMenuItem(req(VALID), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(pool.query.mock.calls[2][0]).toContain('INSERT INTO menu');
    });

    test('201 — kategori yoksa lazy oluşturulur', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })
            .mockResolvedValueOnce({ rows: [] })                     // kategori YOK
            .mockResolvedValueOnce({ rows: [{ category_id: 9 }] })   // INSERT category
            .mockResolvedValueOnce({ rows: [{ item_id: 50, name: 'Pizza', price: 89.9 }] });
        const res = mockRes();

        await menuController.createMenuItem(req(VALID), res);

        expect(res.status).toHaveBeenCalledWith(201);
        expect(pool.query.mock.calls[3][0]).toContain('INSERT INTO category');
        expect(pool.query.mock.calls[4][1][0]).toBe(9); // yeni category_id kullanıldı
    });

    test('kategori eşleşmesi case-insensitive yapılır', async () => {
        pool.query
            .mockResolvedValueOnce({ rows: [{ owner_id: 10 }] })
            .mockResolvedValueOnce({ rows: [{ menu_id: 3 }] })
            .mockResolvedValueOnce({ rows: [{ category_id: 2 }] })
            .mockResolvedValueOnce({ rows: [{ item_id: 50, name: 'X', price: 1 }] });
        const res = mockRes();

        await menuController.createMenuItem(req({ ...VALID, category: 'ANA YEMEK' }), res);

        expect(pool.query.mock.calls[2][0]).toContain('LOWER(name) = LOWER($2)');
    });
});

// ─── updateMenuItem ─────────────────────────────────────────────────────────

describe('updateMenuItem', () => {
    function req(body = {}, itemId = '5') {
        return { params: { itemId }, user: OWNER, body };
    }

    test('400 — geçersiz ürün kimliği', async () => {
        const res = mockRes();
        await menuController.updateMenuItem(req({}, 'abc'), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — ürün yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await menuController.updateMenuItem(req(), res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('403 — BAŞKA bir işletmenin ürünü güncellenemez', async () => {
        pool.query.mockResolvedValueOnce(locatedItem({ owner_id: 999 }));
        const res = mockRes();

        await menuController.updateMenuItem(req({ name: 'Hacklendi' }), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(pool.query).toHaveBeenCalledTimes(1); // UPDATE çalışmamalı
    });

    test('200 — kategori gönderilmezse mevcut category_id korunur', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, name: 'Yeni', price: 10 }] });
        const res = mockRes();

        await menuController.updateMenuItem(req({ name: 'Yeni' }), res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(pool.query.mock.calls[1][1][3]).toBe(2); // located.category_id
    });

    test('200 — kategori değiştiyse yeni category_id çözülür', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ category_id: 8 }] })  // yeni kategori bulundu
            .mockResolvedValueOnce({ rows: [{ item_id: 5, name: 'X', price: 10 }] });
        const res = mockRes();

        await menuController.updateMenuItem(req({ category: 'Tatlı' }), res);

        expect(pool.query.mock.calls[2][1][3]).toBe(8);
    });

    test('gönderilmeyen alanlar null geçilir — COALESCE mevcut değeri korur', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, name: 'X', price: 10 }] });
        const res = mockRes();

        await menuController.updateMenuItem(req({ name: 'Yeni Ad' }), res);

        const params = pool.query.mock.calls[1][1];
        expect(params[0]).toBe('Yeni Ad');
        expect(params[1]).toBeNull(); // price
        expect(params[4]).toBeNull(); // is_green_menu
        expect(params[5]).toBeNull(); // is_available
    });

    test('is_available=false açıkça gönderilebilir (COALESCE tuzağı)', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, name: 'X', price: 10 }] });
        const res = mockRes();

        await menuController.updateMenuItem(req({ is_available: false }), res);

        expect(pool.query.mock.calls[1][1][5]).toBe(false); // null'a düşmemeli
    });
});

// ─── deleteMenuItem ─────────────────────────────────────────────────────────

describe('deleteMenuItem', () => {
    test('400 — geçersiz ürün kimliği', async () => {
        const res = mockRes();
        await menuController.deleteMenuItem({ params: { itemId: 'abc' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('404 — ürün yoksa', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        const res = mockRes();

        await menuController.deleteMenuItem({ params: { itemId: '5' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(404);
    });

    test('403 — BAŞKA bir işletmenin ürünü silinemez', async () => {
        pool.query.mockResolvedValueOnce(locatedItem({ owner_id: 999 }));
        const res = mockRes();

        await menuController.deleteMenuItem({ params: { itemId: '5' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(403);
        // DELETE sorgusu ASLA çalışmamalı
        expect(pool.query).toHaveBeenCalledTimes(1);
        expect(pool.query.mock.calls.some(c => /DELETE/i.test(c[0]))).toBe(false);
    });

    test('200 — sahibi ürünü siler', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rowCount: 1 });
        const res = mockRes();

        await menuController.deleteMenuItem({ params: { itemId: '5' }, user: OWNER }, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(pool.query.mock.calls[1][0]).toContain('DELETE FROM menu_item');
        expect(pool.query.mock.calls[1][1]).toEqual([5]);
    });
});

// ─── uploadMenuItemPhoto ────────────────────────────────────────────────────

describe('uploadMenuItemPhoto', () => {
    function file(overrides = {}) {
        return {
            mimetype: 'image/jpeg', size: 1024,
            originalname: 'yemek.jpg', buffer: Buffer.from('x'), ...overrides,
        };
    }

    function req(fileObj = file(), itemId = '5') {
        return { params: { itemId }, user: OWNER, file: fileObj };
    }

    test('400 — dosya gönderilmemişse', async () => {
        const res = mockRes();
        await menuController.uploadMenuItemPhoto(req(null), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('400 — izin verilmeyen MIME tipi (örn. PDF)', async () => {
        const res = mockRes();
        await menuController.uploadMenuItemPhoto(req(file({ mimetype: 'application/pdf' })), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('400 — 5 MB sınırını aşan dosya', async () => {
        const res = mockRes();
        await menuController.uploadMenuItemPhoto(req(file({ size: 5 * 1024 * 1024 + 1 })), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(fs.writeFile).not.toHaveBeenCalled();
    });

    test('403 — BAŞKA bir işletmenin ürününe fotoğraf yüklenemez', async () => {
        pool.query.mockResolvedValueOnce(locatedItem({ owner_id: 999 }));
        const res = mockRes();

        await menuController.uploadMenuItemPhoto(req(), res);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(fs.writeFile).not.toHaveBeenCalled(); // disk'e hiç yazılmamalı
    });

    test('200 — fotoğraf kaydedilir ve image_url güncellenir', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, image_url: '/uploads/menu/x.jpg' }] });
        const res = mockRes();

        await menuController.uploadMenuItemPhoto(req(), res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(fs.mkdir).toHaveBeenCalled();
        expect(fs.writeFile).toHaveBeenCalledTimes(1);
        expect(pool.query.mock.calls[1][0]).toContain('UPDATE menu_item SET image_url');
    });

    test('dosya adı kullanıcının gönderdiği isimden kurulmaz (path traversal)', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, image_url: '/uploads/menu/x.jpg' }] });
        const res = mockRes();

        await menuController.uploadMenuItemPhoto(
            req(file({ originalname: '../../../etc/passwd' })), res,
        );

        const writtenPath = fs.writeFile.mock.calls[0][0];
        expect(writtenPath).toContain('uploads/menu/');
        expect(writtenPath).not.toContain('..');
        expect(writtenPath).not.toContain('passwd');
        // Ad "itemId_rastgelehex.uzantı" kalıbında olmalı
        expect(writtenPath).toMatch(/\/5_[0-9a-f]{16}\.[a-z0-9]+$/);
    });

    test('uzantısız dosya adı .jpg\'ye düşer', async () => {
        pool.query
            .mockResolvedValueOnce(locatedItem())
            .mockResolvedValueOnce({ rows: [{ item_id: 5, image_url: '/uploads/menu/x.jpg' }] });
        const res = mockRes();

        await menuController.uploadMenuItemPhoto(req(file({ originalname: 'foto' })), res);

        expect(fs.writeFile.mock.calls[0][0]).toMatch(/\.jpg$/);
    });

    test('500 — disk yazma hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockResolvedValueOnce(locatedItem());
        fs.writeFile.mockRejectedValueOnce(new Error('ENOSPC: no space left on device'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await menuController.uploadMenuItemPhoto(req(), res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('ENOSPC');
    });
});

// ─── getGreenMenu ───────────────────────────────────────────────────────────

describe('getGreenMenu', () => {
    test('200 — yalnızca süresi dolmamış ve stoğu olan ürünler', async () => {
        pool.query.mockResolvedValueOnce({ rowCount: 1, rows: [{ green_item_id: 1 }] });
        const res = mockRes();

        await menuController.getGreenMenu({}, res);

        expect(res.status).toHaveBeenCalledWith(200);
        const sql = pool.query.mock.calls[0][0];
        expect(sql).toContain('gm.expiration_time > CURRENT_TIMESTAMP');
        expect(sql).toContain('gm.quantity > 0');
    });

    test('500 — DB hatası iç mesajı sızdırmaz', async () => {
        pool.query.mockRejectedValueOnce(new Error('relation "green_menu" does not exist'));
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await menuController.getGreenMenu({}, res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(JSON.stringify(res.json.mock.calls[0][0])).not.toContain('does not exist');
    });
});
