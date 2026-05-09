const pool = require('../config/db');

// ============================================================================
// İşletme Menü CRUD
// ----------------------------------------------------------------------------
// iOS MenuManagerView bu 4 endpoint'i kullanır:
//   GET    /api/restaurants/:rid/menu/items
//   POST   /api/restaurants/:rid/menu/items
//   PUT    /api/menu/items/:itemId
//   DELETE /api/menu/items/:itemId
//
// Tümü authMiddleware + ownerOnly arkasında. PUT/DELETE'te ek olarak ürünün
// gerçekten istek sahibinin restoranına ait olduğu doğrulanır.
//
// Kategori string olarak gelir/gider: "Pizza", "Burger" vs.
// Backend bu string'i ilgili menünün altındaki category tablosunda arar,
// yoksa otomatik olarak yeni bir kategori satırı oluşturur (lazy upsert).
// ============================================================================

/**
 * Verilen restaurant_id için tek menu kaydını bulur, yoksa oluşturur.
 * Her restoranın bir menu satırı olmalı (1:1 varsayımı).
 */
async function getOrCreateMenu(restaurantId) {
    const existing = await pool.query(
        'SELECT menu_id FROM menu WHERE restaurant_id = $1 LIMIT 1',
        [restaurantId]
    );
    if (existing.rows.length > 0) return existing.rows[0].menu_id;

    const created = await pool.query(
        'INSERT INTO menu (restaurant_id) VALUES ($1) RETURNING menu_id',
        [restaurantId]
    );
    return created.rows[0].menu_id;
}

/**
 * Verilen menu_id altında categoryName ile eşleşen category_id'yi bulur.
 * Yoksa yeni kategori oluşturup id'yi döner. Eşleşme case-insensitive.
 */
async function getOrCreateCategoryId(menuId, categoryName) {
    const safeName = String(categoryName || '').trim() || 'Diğer';

    const existing = await pool.query(
        'SELECT category_id FROM category WHERE menu_id = $1 AND LOWER(name) = LOWER($2) LIMIT 1',
        [menuId, safeName]
    );
    if (existing.rows.length > 0) return existing.rows[0].category_id;

    const created = await pool.query(
        'INSERT INTO category (menu_id, name) VALUES ($1, $2) RETURNING category_id',
        [menuId, safeName]
    );
    return created.rows[0].category_id;
}

/**
 * iOS'un beklediği şekle dönüştürür.
 *   { item_id, name, price, description, category, is_green_menu, is_available, image_url }
 */
function shapeMenuItem(row) {
    return {
        item_id: row.item_id,
        name: row.name,
        price: row.price !== null && row.price !== undefined ? Number(row.price) : 0,
        description: row.description,
        category: row.category,
        is_green_menu: row.is_green_menu === true,
        is_available: row.is_available === true,
        image_url: row.image_url
    };
}

/**
 * itemId üzerinden ürünün ait olduğu restoranı ve sahibini bulur.
 * Returns: { item_id, restaurant_id, owner_id, menu_id, category_id }
 */
async function locateItem(itemId) {
    const result = await pool.query(`
        SELECT mi.item_id, r.restaurant_id, r.owner_id, m.menu_id, mi.category_id
        FROM menu_item mi
        JOIN category c   ON c.category_id = mi.category_id
        JOIN menu m       ON m.menu_id = c.menu_id
        JOIN restaurant r ON r.restaurant_id = m.restaurant_id
        WHERE mi.item_id = $1
        LIMIT 1
    `, [itemId]);
    return result.rows[0] || null;
}

/** GET /api/restaurants/:rid/menu/items */
exports.getOwnerMenuItems = async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.rid, 10);
        if (Number.isNaN(restaurantId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz restoran kimliği.' });
        }

        // Sahiplik kontrolü
        const ownerCheck = await pool.query(
            'SELECT owner_id FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (ownerCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }
        if (ownerCheck.rows[0].owner_id !== req.user.user_id) {
            return res.status(403).json({ success: false, message: 'Bu restoranın menüsünü göremezsiniz.' });
        }

        const result = await pool.query(`
            SELECT mi.item_id,
                   mi.name,
                   mi.price::float        AS price,
                   mi.description,
                   c.name                 AS category,
                   mi.is_green_menu,
                   mi.is_available,
                   mi.image_url
            FROM menu_item mi
            JOIN category c ON c.category_id = mi.category_id
            JOIN menu m     ON m.menu_id = c.menu_id
            WHERE m.restaurant_id = $1
            ORDER BY mi.item_id ASC
        `, [restaurantId]);

        res.status(200).json({
            success: true,
            data: result.rows.map(shapeMenuItem)
        });
    } catch (error) {
        console.error('getOwnerMenuItems Error:', error);
        res.status(500).json({ success: false, message: 'Menü ürünleri getirilirken sunucu hatası oluştu.' });
    }
};

/** POST /api/restaurants/:rid/menu/items */
exports.createMenuItem = async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.rid, 10);
        if (Number.isNaN(restaurantId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz restoran kimliği.' });
        }

        const { name, price, description, category, is_green_menu, is_available } = req.body;

        if (!name || price === undefined || price === null || !category) {
            return res.status(400).json({
                success: false,
                message: 'name, price ve category alanları zorunludur.'
            });
        }

        // Sahiplik kontrolü
        const ownerCheck = await pool.query(
            'SELECT owner_id FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (ownerCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }
        if (ownerCheck.rows[0].owner_id !== req.user.user_id) {
            return res.status(403).json({ success: false, message: 'Bu restorana ürün ekleyemezsiniz.' });
        }

        const menuId = await getOrCreateMenu(restaurantId);
        const categoryId = await getOrCreateCategoryId(menuId, category);

        const inserted = await pool.query(`
            INSERT INTO menu_item (category_id, name, price, description, is_green_menu, is_available)
            VALUES ($1, $2, $3, $4, COALESCE($5, FALSE), COALESCE($6, TRUE))
            RETURNING item_id, name, price::float AS price, description, is_green_menu, is_available, image_url,
                      (SELECT name FROM category WHERE category_id = $1) AS category
        `, [categoryId, name, price, description || null, is_green_menu, is_available]);

        const row = inserted.rows[0];

        res.status(201).json({
            success: true,
            data: shapeMenuItem(row)
        });
    } catch (error) {
        console.error('createMenuItem Error:', error);
        res.status(500).json({ success: false, message: 'Ürün eklenirken sunucu hatası oluştu.' });
    }
};

/** PUT /api/menu/items/:itemId */
exports.updateMenuItem = async (req, res) => {
    try {
        const itemId = parseInt(req.params.itemId, 10);
        if (Number.isNaN(itemId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz ürün kimliği.' });
        }

        const located = await locateItem(itemId);
        if (!located) {
            return res.status(404).json({ success: false, message: 'Ürün bulunamadı.' });
        }
        if (located.owner_id !== req.user.user_id) {
            return res.status(403).json({ success: false, message: 'Bu ürünü güncelleyemezsiniz.' });
        }

        const { name, price, description, category, is_green_menu, is_available } = req.body;

        // Kategori değiştiyse yeni category_id'yi bul/oluştur
        let categoryId = located.category_id;
        if (typeof category === 'string' && category.trim().length > 0) {
            categoryId = await getOrCreateCategoryId(located.menu_id, category);
        }

        const updated = await pool.query(`
            UPDATE menu_item
            SET name          = COALESCE($1, name),
                price         = COALESCE($2, price),
                description   = $3,
                category_id   = $4,
                is_green_menu = COALESCE($5, is_green_menu),
                is_available  = COALESCE($6, is_available)
            WHERE item_id = $7
            RETURNING item_id, name, price::float AS price, description, is_green_menu, is_available, image_url,
                      (SELECT name FROM category WHERE category_id = $4) AS category
        `, [
            name ?? null,
            price ?? null,
            description ?? null,
            categoryId,
            is_green_menu ?? null,
            is_available ?? null,
            itemId
        ]);

        const row = updated.rows[0];

        res.status(200).json({
            success: true,
            data: shapeMenuItem(row)
        });
    } catch (error) {
        console.error('updateMenuItem Error:', error);
        res.status(500).json({ success: false, message: 'Ürün güncellenirken sunucu hatası oluştu.' });
    }
};

/** DELETE /api/menu/items/:itemId */
exports.deleteMenuItem = async (req, res) => {
    try {
        const itemId = parseInt(req.params.itemId, 10);
        if (Number.isNaN(itemId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz ürün kimliği.' });
        }

        const located = await locateItem(itemId);
        if (!located) {
            return res.status(404).json({ success: false, message: 'Ürün bulunamadı.' });
        }
        if (located.owner_id !== req.user.user_id) {
            return res.status(403).json({ success: false, message: 'Bu ürünü silemezsiniz.' });
        }

        await pool.query('DELETE FROM menu_item WHERE item_id = $1', [itemId]);

        res.status(200).json({
            success: true,
            message: 'Silindi.'
        });
    } catch (error) {
        console.error('deleteMenuItem Error:', error);
        res.status(500).json({ success: false, message: 'Ürün silinirken sunucu hatası oluştu.' });
    }
};

// ============================================================================
// Yeşil Menü (mevcut)
// ============================================================================

exports.getGreenMenu = async (req, res) => {
    try {
        const query = `
            SELECT gm.green_item_id, gm.quantity, gm.discounted_price, gm.expiration_time, 
                   mi.item_id, mi.name, mi.description, mi.price as original_price, mi.dietary_tags
            FROM green_menu gm
            JOIN menu_item mi ON gm.item_id = mi.item_id
            WHERE gm.expiration_time > CURRENT_TIMESTAMP AND gm.quantity > 0
            ORDER BY gm.expiration_time ASC
        `;
        const result = await pool.query(query);
        res.status(200).json({
            success: true,
            count: result.rowCount,
            data: result.rows
        });
    } catch (error) {
        console.error('Green Menu Error:', error);
        res.status(500).json({ success: false, message: 'Yeşil menü getirilirken sunucu hatası oluştu.' });
    }
};
