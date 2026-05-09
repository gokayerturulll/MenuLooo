// backend/controllers/reviewController.js
// Restoran yorum/değerlendirme controller'ı.
//
//   GET  /api/restaurants/:id/reviews   → public (kullanıcı adıyla join'li liste)
//   POST /api/restaurants/:id/reviews   → authMiddleware (içerik + opsiyonel puanlar)

const pool = require('../config/db');

// ─── Helpers ────────────────────────────────────────────────────────────────

function parseRating(value) {
    if (value === null || value === undefined || value === '') return null;
    const n = Number(value);
    if (!Number.isInteger(n) || n < 1 || n > 5) {
        const err = new Error('Puanlar 1 ile 5 arasında bir tam sayı olmalıdır.');
        err.code = 'INVALID_RATING';
        throw err;
    }
    return n;
}

const REVIEW_SELECT_COLUMNS = `
    r.review_id,
    r.restaurant_id,
    r.user_id,
    u.username AS user_name,
    r.content,
    r.rating_taste,
    r.rating_service,
    r.rating_attitude,
    r.created_at
`;

// ─── GET /restaurants/:id/reviews ───────────────────────────────────────────

exports.getRestaurantReviews = async (req, res) => {
    const restaurantId = parseInt(req.params.id, 10);
    if (!Number.isInteger(restaurantId)) {
        return res.status(400).json({
            success: false,
            message: 'Geçersiz restoran ID.'
        });
    }

    try {
        const { rows } = await pool.query(
            `SELECT ${REVIEW_SELECT_COLUMNS}
             FROM review r
             JOIN "user" u ON u.user_id = r.user_id
             WHERE r.restaurant_id = $1
             ORDER BY r.created_at DESC`,
            [restaurantId]
        );

        res.status(200).json({
            success: true,
            count: rows.length,
            data: rows
        });
    } catch (err) {
        console.error('Error fetching reviews:', err.message);
        res.status(500).json({
            success: false,
            message: 'Yorumlar getirilirken sunucu hatası oluştu.'
        });
    }
};

// ─── POST /restaurants/:id/reviews ──────────────────────────────────────────

exports.addReview = async (req, res) => {
    const restaurantId = parseInt(req.params.id, 10);
    if (!Number.isInteger(restaurantId)) {
        return res.status(400).json({
            success: false,
            message: 'Geçersiz restoran ID.'
        });
    }

    const userId = req.user?.user_id;
    if (!userId) {
        return res.status(401).json({
            success: false,
            message: 'Oturum bilgisi alınamadı.'
        });
    }

    const { content, rating_taste, rating_service, rating_attitude } = req.body || {};
    const trimmedContent = typeof content === 'string' ? content.trim() : '';

    let taste, service, attitude;
    try {
        taste    = parseRating(rating_taste);
        service  = parseRating(rating_service);
        attitude = parseRating(rating_attitude);
    } catch (err) {
        return res.status(400).json({ success: false, message: err.message });
    }

    // En az içerik veya bir puan zorunlu — boş yorum kabul etme
    const hasAnyRating = taste !== null || service !== null || attitude !== null;
    if (!trimmedContent && !hasAnyRating) {
        return res.status(400).json({
            success: false,
            message: 'Yorum metni veya en az bir puan girmelisiniz.'
        });
    }

    try {
        // Restoran var mı? (FK violation'dan önce daha temiz hata mesajı)
        const exists = await pool.query(
            'SELECT 1 FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (exists.rowCount === 0) {
            return res.status(404).json({
                success: false,
                message: 'Restoran bulunamadı.'
            });
        }

        const { rows } = await pool.query(
            `WITH inserted AS (
                INSERT INTO review
                    (restaurant_id, user_id, content, rating_taste, rating_service, rating_attitude)
                VALUES ($1, $2, $3, $4, $5, $6)
                RETURNING *
            )
            SELECT ${REVIEW_SELECT_COLUMNS}
            FROM inserted r
            JOIN "user" u ON u.user_id = r.user_id`,
            [
                restaurantId,
                userId,
                trimmedContent || null,
                taste,
                service,
                attitude
            ]
        );

        res.status(201).json({
            success: true,
            data: rows[0]
        });
    } catch (err) {
        console.error('Error creating review:', err.message);
        res.status(500).json({
            success: false,
            message: 'Yorum kaydedilirken sunucu hatası oluştu.'
        });
    }
};
