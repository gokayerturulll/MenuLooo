const pool = require('../config/db');

exports.getAllRestaurants = async (req, res) => {
    try {
        const query = `
            SELECT 
                restaurant_id, 
                owner_id, 
                business_name, 
                address,
                ST_X(location_point::geometry) as longitude,
                ST_Y(location_point::geometry) as latitude
            FROM restaurant
        `;
        const result = await pool.query(query);
        res.status(200).json({
            success: true,
            count: result.rowCount,
            data: result.rows
        });
    } catch (err) {
        console.error('Error fetching restaurants:', err.message);
        res.status(500).json({
            success: false,
            message: 'Restoranlar getirilirken sunucu hatası oluştu.'
        });
    }
};

// ============================================================================
// Restoran Profili — Detay ve Güncelleme (MyBusinessView)
// ----------------------------------------------------------------------------
//   GET /api/restaurants/:rid           → public (restoran detayı)
//   PUT /api/restaurants/:rid           → ownerOnly (kendi restoranını günceller)
//
// working_hours JSONB şeması (iOS WorkingHours struct'ı ile birebir):
// {
//   "open_hour": 9, "open_minute": 0,
//   "close_hour": 22, "close_minute": 0,
//   "open_days": { "Pazartesi": true, "Salı": true, ... }
// }
// ============================================================================

const RESTAURANT_DETAIL_COLUMNS = `
    restaurant_id,
    owner_id,
    business_name,
    address,
    phone,
    website,
    description,
    cuisine_type,
    working_hours,
    ST_X(location_point::geometry) AS longitude,
    ST_Y(location_point::geometry) AS latitude
`;

/** GET /api/restaurants/:rid */
exports.getRestaurantById = async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.rid, 10);
        if (Number.isNaN(restaurantId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz restoran kimliği.' });
        }

        const result = await pool.query(
            `SELECT ${RESTAURANT_DETAIL_COLUMNS} FROM restaurant WHERE restaurant_id = $1 LIMIT 1`,
            [restaurantId]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }

        res.status(200).json({
            success: true,
            data: result.rows[0]
        });
    } catch (error) {
        console.error('getRestaurantById Error:', error);
        res.status(500).json({ success: false, message: 'Restoran detayları getirilemedi.' });
    }
};

/** PUT /api/restaurants/:rid — ownerOnly */
exports.updateRestaurant = async (req, res) => {
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
            return res.status(403).json({ success: false, message: 'Bu restoranı güncelleyemezsiniz.' });
        }

        const {
            business_name,
            address,
            phone,
            website,
            description,
            cuisine_type,
            latitude,
            longitude,
            working_hours
        } = req.body;

        const hasCoords = (typeof latitude === 'number' && typeof longitude === 'number');
        const workingHoursJson = working_hours ? JSON.stringify(working_hours) : null;

        // Koordinat geldiyse PostGIS POINT'i de güncelle, gelmediyse mevcut korunur.
        const sql = hasCoords
            ? `
                UPDATE restaurant SET
                    business_name  = COALESCE($1, business_name),
                    address        = COALESCE($2, address),
                    phone          = COALESCE($3, phone),
                    website        = COALESCE($4, website),
                    description    = COALESCE($5, description),
                    cuisine_type   = COALESCE($6, cuisine_type),
                    working_hours  = COALESCE($7::jsonb, working_hours),
                    location_point = ST_SetSRID(ST_MakePoint($8, $9), 4326)::geometry
                WHERE restaurant_id = $10
                RETURNING ${RESTAURANT_DETAIL_COLUMNS}
            `
            : `
                UPDATE restaurant SET
                    business_name = COALESCE($1, business_name),
                    address       = COALESCE($2, address),
                    phone         = COALESCE($3, phone),
                    website       = COALESCE($4, website),
                    description   = COALESCE($5, description),
                    cuisine_type  = COALESCE($6, cuisine_type),
                    working_hours = COALESCE($7::jsonb, working_hours)
                WHERE restaurant_id = $8
                RETURNING ${RESTAURANT_DETAIL_COLUMNS}
            `;

        const params = hasCoords
            ? [business_name ?? null, address ?? null, phone ?? null, website ?? null,
               description ?? null, cuisine_type ?? null, workingHoursJson,
               longitude, latitude, restaurantId]
            : [business_name ?? null, address ?? null, phone ?? null, website ?? null,
               description ?? null, cuisine_type ?? null, workingHoursJson, restaurantId];

        const updated = await pool.query(sql, params);

        res.status(200).json({
            success: true,
            data: updated.rows[0]
        });
    } catch (error) {
        console.error('updateRestaurant Error:', error);
        res.status(500).json({ success: false, message: 'Restoran güncellenirken sunucu hatası oluştu.' });
    }
};

exports.getRestaurantMenu = async (req, res) => {
    try {
        const { id } = req.params;
        
        // Restorana ait menüyü bul
        const menuResult = await pool.query('SELECT menu_id FROM menu WHERE restaurant_id = $1', [id]);
        if (menuResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Bu restorana ait menü bulunamadı.' });
        }
        const menuId = menuResult.rows[0].menu_id;
        
        // Kategorileri ve her kategorinin altındaki ürünleri json_agg ile çek
        const query = `
            SELECT
                c.category_id,
                c.name as category_name,
                COALESCE(
                    json_agg(
                        json_build_object(
                            'item_id', mi.item_id,
                            'name', mi.name,
                            'price', (mi.price)::double precision,
                            'description', mi.description,
                            'image_url', mi.image_url,
                            'dietary_tags', COALESCE(mi.dietary_tags, ARRAY[]::text[])
                        )
                    ) FILTER (WHERE mi.item_id IS NOT NULL), '[]'
                ) as items
            FROM category c
            LEFT JOIN menu_item mi ON c.category_id = mi.category_id
            WHERE c.menu_id = $1
            GROUP BY c.category_id, c.name
            ORDER BY c.category_id
        `;

        const categoriesResult = await pool.query(query, [menuId]);

        res.status(200).json({
            success: true,
            data: {
                menu_id: Number(menuId),
                restaurant_id: parseInt(id, 10),
                categories: categoriesResult.rows
            }
        });
    } catch (error) {
        console.error('Get Menu Error:', error);
        res.status(500).json({ success: false, message: 'Menü getirilirken sunucu hatası oluştu.' });
    }
};
