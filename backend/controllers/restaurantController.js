const pool   = require('../config/db');
const path   = require('path');
const fs     = require('fs/promises');
const crypto = require('crypto');

// ── is_open expression (her iki working_hours şemasını destekler) ────────────
// 1) Yeni şema: { open_hour, open_minute, close_hour, close_minute, open_days }
// 2) Eski şema: { open: "HH:MM", close: "HH:MM" }  (mock_data fallback)
// working_hours null ise açık varsayılır.
const IS_OPEN_EXPR = `
    CASE
        WHEN r.working_hours IS NULL THEN true
        WHEN r.working_hours ? 'open_hour' THEN (
            COALESCE((r.working_hours->'open_days'->>(
                CASE EXTRACT(DOW FROM NOW())::int
                    WHEN 0 THEN 'Pazar'
                    WHEN 1 THEN 'Pazartesi'
                    WHEN 2 THEN 'Salı'
                    WHEN 3 THEN 'Çarşamba'
                    WHEN 4 THEN 'Perşembe'
                    WHEN 5 THEN 'Cuma'
                    WHEN 6 THEN 'Cumartesi'
                END
            ))::boolean, false)
            AND (EXTRACT(HOUR FROM NOW())::int * 60 + EXTRACT(MINUTE FROM NOW())::int)
                BETWEEN ((r.working_hours->>'open_hour')::int * 60 + COALESCE((r.working_hours->>'open_minute')::int, 0))
                AND     ((r.working_hours->>'close_hour')::int * 60 + COALESCE((r.working_hours->>'close_minute')::int, 0))
        )
        WHEN r.working_hours ? 'open' AND r.working_hours ? 'close' THEN
            NOW()::time BETWEEN (r.working_hours->>'open')::time AND (r.working_hours->>'close')::time
        ELSE true
    END
`;

/**
 * GET /api/restaurants
 *
 * Query parameters (hepsi opsiyonel):
 *   lat, lng     — kullanıcı koordinatı (PostGIS distance hesabı için)
 *   radius       — km cinsinden mesafe filtresi (lat+lng yoksa yok sayılır)
 *   dietary      — virgülle ayrılmış tag listesi ("Vegan,Glutensiz") — OR semantiği
 *   open_now     — "true" ise sadece açık olanlar
 *   sort         — best_match | rating_desc | distance_asc | price_asc | price_desc
 */
exports.getAllRestaurants = async (req, res) => {
    try {
        const lat       = parseFloat(req.query.lat);
        const lng       = parseFloat(req.query.lng);
        const hasCoords = Number.isFinite(lat) && Number.isFinite(lng);

        const radiusKm  = parseFloat(req.query.radius);
        const hasRadius = hasCoords && Number.isFinite(radiusKm) && radiusKm > 0;

        const openNow   = req.query.open_now === 'true';

        const dietary   = typeof req.query.dietary === 'string' && req.query.dietary.length > 0
            ? req.query.dietary.split(',').map(s => s.trim()).filter(Boolean).slice(0, 10)
            : null;

        const sort      = req.query.sort || 'best_match';

        // Dinamik parametre listesi
        const params = [];
        const place  = (val) => { params.push(val); return `$${params.length}`; };

        // ── Distance hesabı ──
        let distanceSelect = 'NULL::double precision AS distance_m';
        let userPointExpr  = null;
        if (hasCoords) {
            const lngP = place(lng);
            const latP = place(lat);
            userPointExpr  = `ST_SetSRID(ST_MakePoint(${lngP}, ${latP}), 4326)::geography`;
            distanceSelect = `ST_Distance(r.location_point::geography, ${userPointExpr}) AS distance_m`;
        }

        // ── WHERE filtreleri ──
        const whereClauses = [];

        if (hasRadius && userPointExpr) {
            const rP = place(radiusKm * 1000);
            whereClauses.push(`ST_DWithin(r.location_point::geography, ${userPointExpr}, ${rP})`);
        }

        if (dietary && dietary.length > 0) {
            const dP = place(dietary);
            whereClauses.push(`EXISTS (
                SELECT 1 FROM menu mn
                JOIN category cat   ON mn.menu_id = cat.menu_id
                JOIN menu_item mit  ON cat.category_id = mit.category_id
                WHERE mn.restaurant_id = r.restaurant_id
                  AND mit.dietary_tags && ${dP}::text[]
            )`);
        }

        if (openNow) {
            whereClauses.push(`(${IS_OPEN_EXPR}) = true`);
        }

        // ── Sıralama ──
        let orderClause;
        switch (sort) {
            case 'rating_desc':  orderClause = 'avg_rating DESC NULLS LAST'; break;
            case 'distance_asc': orderClause = hasCoords ? 'distance_m ASC NULLS LAST' : 'avg_rating DESC NULLS LAST'; break;
            case 'price_asc':   orderClause = 'avg_price ASC NULLS LAST'; break;
            case 'price_desc':  orderClause = 'avg_price DESC NULLS LAST'; break;
            default:            orderClause = 'avg_rating DESC NULLS LAST';
        }

        const whereSql = whereClauses.length > 0 ? `WHERE ${whereClauses.join(' AND ')}` : '';

        const query = `
            SELECT
                r.restaurant_id,
                r.owner_id,
                r.business_name,
                r.address,
                r.cuisine_type,
                ST_X(r.location_point::geometry) AS longitude,
                ST_Y(r.location_point::geometry) AS latitude,
                COALESCE(
                    ROUND(AVG(
                        NULLIF((rv.rating_taste + rv.rating_service + rv.rating_attitude) / 3.0, 0)
                    )::numeric, 1),
                    0.0
                )::double precision                     AS avg_rating,
                COUNT(rv.review_id)::int                AS review_count,
                COALESCE(AVG(mi.price), 0)::double precision AS avg_price,
                CASE
                    WHEN COALESCE(AVG(mi.price), 0) < 100 THEN '₺'
                    WHEN COALESCE(AVG(mi.price), 0) < 200 THEN '₺₺'
                    WHEN COALESCE(AVG(mi.price), 0) < 350 THEN '₺₺₺'
                    ELSE '₺₺₺₺'
                END                                     AS price_range,
                ${distanceSelect},
                (${IS_OPEN_EXPR})                       AS is_open
            FROM restaurant r
            LEFT JOIN review rv    ON r.restaurant_id = rv.restaurant_id
            LEFT JOIN menu m       ON r.restaurant_id = m.restaurant_id
            LEFT JOIN category c   ON m.menu_id = c.menu_id
            LEFT JOIN menu_item mi ON c.category_id = mi.category_id
            ${whereSql}
            GROUP BY r.restaurant_id
            ORDER BY ${orderClause}
            LIMIT 200
        `;

        const result = await pool.query(query, params);
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

        // ─── Input doğrulama ─────────────────────────────────────────────────────────
        const PHONE_REGEX = /^\+?[\d\s\-(). ]{7,20}$/;
        const MAX_LEN = { business_name: 100, address: 200, description: 1000, website: 250, cuisine_type: 100 };

        if (business_name !== undefined && business_name !== null) {
            if (typeof business_name !== 'string' || business_name.trim().length > MAX_LEN.business_name) {
                return res.status(400).json({ success: false, message: 'İşletme adı en fazla 100 karakter olabilir.' });
            }
        }
        if (address !== undefined && address !== null && typeof address === 'string' && address.length > MAX_LEN.address) {
            return res.status(400).json({ success: false, message: 'Adres en fazla 200 karakter olabilir.' });
        }
        if (phone !== undefined && phone !== null) {
            if (typeof phone !== 'string' || (!PHONE_REGEX.test(phone))) {
                return res.status(400).json({ success: false, message: 'Geçerli bir telefon numarası giriniz.' });
            }
        }
        if (website !== undefined && website !== null && typeof website === 'string' && website.length > MAX_LEN.website) {
            return res.status(400).json({ success: false, message: 'Web sitesi adresi en fazla 250 karakter olabilir.' });
        }
        if (description !== undefined && description !== null && typeof description === 'string' && description.length > MAX_LEN.description) {
            return res.status(400).json({ success: false, message: 'Açıklama en fazla 1000 karakter olabilir.' });
        }

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

/** GET /api/restaurants/:id/stats — public */
exports.getRestaurantStats = async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.id, 10);
        if (Number.isNaN(restaurantId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz restoran kimliği.' });
        }

        const result = await pool.query(`
            SELECT
                r.restaurant_id,
                COALESCE(
                    ROUND(AVG(
                        NULLIF((rv.rating_taste + rv.rating_service + rv.rating_attitude) / 3.0, 0)
                    )::numeric, 1),
                    0.0
                )::double precision                        AS avg_rating,
                COUNT(rv.review_id)::int                  AS review_count,
                CASE
                    WHEN COALESCE(AVG(mi.price), 0) < 100  THEN '₺'
                    WHEN COALESCE(AVG(mi.price), 0) < 200  THEN '₺₺'
                    WHEN COALESCE(AVG(mi.price), 0) < 350  THEN '₺₺₺'
                    ELSE '₺₺₺₺'
                END                                        AS price_range
            FROM restaurant r
            LEFT JOIN review rv ON r.restaurant_id = rv.restaurant_id
            LEFT JOIN menu m    ON r.restaurant_id = m.restaurant_id
            LEFT JOIN category c ON m.menu_id = c.menu_id
            LEFT JOIN menu_item mi ON c.category_id = mi.category_id
            WHERE r.restaurant_id = $1
            GROUP BY r.restaurant_id
        `, [restaurantId]);

        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }

        res.status(200).json({ success: true, data: result.rows[0] });
    } catch (error) {
        console.error('getRestaurantStats Error:', error);
        res.status(500).json({ success: false, message: 'İstatistikler alınamadı.' });
    }
};

// ============================================================================
// Restoran Profil Fotoğrafı Yükleme
// ----------------------------------------------------------------------------
// POST /api/restaurants/:id/images  — authMiddleware + ownerOnly
//
// PLACEHOLDER: local dosya sistemi (backend/uploads/restaurants/).
// Production'da S3 / Cloudinary / Cloudflare R2 önerilir.
// ============================================================================

const RESTAURANT_UPLOAD_DIR  = path.join(__dirname, '..', 'uploads', 'restaurants');
const RESTAURANT_ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/heic']);
const RESTAURANT_MAX_BYTES    = 5 * 1024 * 1024; // 5 MB

exports.uploadRestaurantImage = async (req, res) => {
    try {
        const restaurantId = parseInt(req.params.id, 10);
        if (Number.isNaN(restaurantId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz restoran kimliği.' });
        }

        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Görsel dosyası eksik.' });
        }
        if (!RESTAURANT_ALLOWED_MIME.has(req.file.mimetype)) {
            return res.status(400).json({ success: false, message: 'Sadece JPEG, PNG, WebP veya HEIC kabul edilir.' });
        }
        if (req.file.size > RESTAURANT_MAX_BYTES) {
            return res.status(400).json({ success: false, message: 'Dosya 5 MB sınırını aşıyor.' });
        }

        const ownerCheck = await pool.query(
            'SELECT owner_id FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (ownerCheck.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }
        if (ownerCheck.rows[0].owner_id !== req.user.user_id) {
            return res.status(403).json({ success: false, message: 'Bu restoranın görselini değiştiremezsiniz.' });
        }

        await fs.mkdir(RESTAURANT_UPLOAD_DIR, { recursive: true });

        const ext     = (path.extname(req.file.originalname || '') || '.jpg').toLowerCase().slice(0, 6);
        const safeExt = /^\.[a-z0-9]+$/.test(ext) ? ext : '.jpg';
        const filename = `${restaurantId}_${crypto.randomBytes(8).toString('hex')}${safeExt}`;
        const filePath = path.join(RESTAURANT_UPLOAD_DIR, filename);

        await fs.writeFile(filePath, req.file.buffer);

        const imageUrl = `/uploads/restaurants/${filename}`;

        const updated = await pool.query(
            `UPDATE restaurant SET image_url = $1
             WHERE restaurant_id = $2
             RETURNING restaurant_id, image_url`,
            [imageUrl, restaurantId]
        );

        return res.status(200).json({
            success: true,
            data: {
                restaurant_id: updated.rows[0].restaurant_id,
                image_url:     updated.rows[0].image_url,
            },
        });
    } catch (error) {
        console.error('[uploadRestaurantImage]', error.message);
        res.status(500).json({ success: false, message: 'Görsel yüklenirken sunucu hatası oluştu.' });
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
