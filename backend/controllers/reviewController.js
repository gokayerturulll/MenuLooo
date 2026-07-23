// backend/controllers/reviewController.js
//
//   GET  /api/restaurants/:id/reviews   → public
//   POST /api/restaurants/:id/reviews   → authMiddleware

const pool = require('../config/db');

const CONTENT_MAX_LEN = 2000;

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
    if (!Number.isInteger(restaurantId) || restaurantId <= 0) {
        return res.status(400).json({ success: false, message: 'Geçersiz restoran ID.' });
    }

    try {
        // LEFT JOIN review_reply — reply yoksa NULL alanlar döner.
        // İşletme yanıtı varsa iOS bunu kart altında "İşletme Yanıtı" olarak gösterir.
        const { rows } = await pool.query(
            `SELECT ${REVIEW_SELECT_COLUMNS},
                    rr.reply_id          AS reply_id,
                    rr.content           AS reply_content,
                    rr.created_at        AS reply_created_at,
                    ru.username          AS reply_author_name
             FROM review r
             JOIN "user" u ON u.user_id = r.user_id
             LEFT JOIN review_reply rr ON rr.review_id = r.review_id
             LEFT JOIN "user" ru ON ru.user_id = rr.user_id
             WHERE r.restaurant_id = $1
             ORDER BY r.created_at DESC`,
            [restaurantId]
        );

        res.status(200).json({ success: true, count: rows.length, data: rows });
    } catch (err) {
        console.error('Error fetching reviews:', err.message);
        res.status(500).json({ success: false, message: 'Yorumlar getirilirken sunucu hatası oluştu.' });
    }
};

// ─── GET /me/reviews ────────────────────────────────────────────────────────
exports.getUserReviews = async (req, res) => {
    const userId = req.user?.user_id;
    if (!userId) {
        return res.status(401).json({ success: false, message: 'Oturum bilgisi alınamadı.' });
    }

    try {
        const { rows } = await pool.query(
            `SELECT ${REVIEW_SELECT_COLUMNS},
                    rr.reply_id          AS reply_id,
                    rr.content           AS reply_content,
                    rr.created_at        AS reply_created_at,
                    ru.username          AS reply_author_name
             FROM review r
             JOIN "user" u ON u.user_id = r.user_id
             LEFT JOIN review_reply rr ON rr.review_id = r.review_id
             LEFT JOIN "user" ru ON ru.user_id = rr.user_id
             WHERE r.user_id = $1
             ORDER BY r.created_at DESC`,
            [userId]
        );

        res.status(200).json({ success: true, count: rows.length, data: rows });
    } catch (err) {
        console.error('Error fetching user reviews:', err.message);
        res.status(500).json({ success: false, message: 'Yorumlarınız getirilirken sunucu hatası oluştu.' });
    }
};

// ─── POST /restaurants/:id/reviews ──────────────────────────────────────────

exports.addReview = async (req, res) => {
    const restaurantId = parseInt(req.params.id, 10);
    if (!Number.isInteger(restaurantId) || restaurantId <= 0) {
        return res.status(400).json({ success: false, message: 'Geçersiz restoran ID.' });
    }

    const userId = req.user?.user_id;
    if (!userId) {
        return res.status(401).json({ success: false, message: 'Oturum bilgisi alınamadı.' });
    }

    const { content, rating_taste, rating_service, rating_attitude } = req.body || {};
    const trimmedContent = typeof content === 'string' ? content.trim() : '';

    if (trimmedContent.length > CONTENT_MAX_LEN) {
        return res.status(400).json({
            success: false,
            message: `Yorum metni en fazla ${CONTENT_MAX_LEN} karakter olabilir.`
        });
    }

    let taste, service, attitude;
    try {
        taste    = parseRating(rating_taste);
        service  = parseRating(rating_service);
        attitude = parseRating(rating_attitude);
    } catch (err) {
        return res.status(400).json({ success: false, message: err.message });
    }

    const hasAnyRating = taste !== null || service !== null || attitude !== null;
    if (!trimmedContent && !hasAnyRating) {
        return res.status(400).json({
            success: false,
            message: 'Yorum metni veya en az bir puan girmelisiniz.'
        });
    }

    try {
        const exists = await pool.query(
            'SELECT 1 FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (exists.rowCount === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
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
            [restaurantId, userId, trimmedContent || null, taste, service, attitude]
        );

        res.status(201).json({ success: true, data: rows[0] });
    } catch (err) {
        console.error('Error creating review:', err.message);
        res.status(500).json({ success: false, message: 'Yorum kaydedilirken sunucu hatası oluştu.' });
    }
};

// ─── POST /restaurants/:id/reviews/:reviewId/reply ────────────────────────
// İşletme sahibi müşteri yorumuna yanıt verir. Sadece restoranın gerçek sahibi
// (owner_id == req.user.user_id) yazabilir. Her review tek bir reply alır;
// tekrar POST → 409 (UNIQUE constraint).

exports.addReply = async (req, res) => {
    const restaurantId = parseInt(req.params.id, 10);
    const reviewId     = parseInt(req.params.reviewId, 10);

    if (!Number.isInteger(restaurantId) || restaurantId <= 0 ||
        !Number.isInteger(reviewId)     || reviewId <= 0) {
        return res.status(400).json({ success: false, message: 'Geçersiz restoran veya yorum ID.' });
    }

    const userId = req.user?.user_id;
    if (!userId) {
        return res.status(401).json({ success: false, message: 'Oturum bilgisi alınamadı.' });
    }

    const { content } = req.body || {};
    const trimmed = typeof content === 'string' ? content.trim() : '';

    if (trimmed.length === 0 || trimmed.length > 1000) {
        return res.status(400).json({
            success: false,
            message: 'Yanıt 1-1000 karakter arasında olmalıdır.'
        });
    }

    try {
        // 1. Restoran sahibi mi?
        const ownerQ = await pool.query(
            'SELECT owner_id FROM restaurant WHERE restaurant_id = $1',
            [restaurantId]
        );
        if (ownerQ.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Restoran bulunamadı.' });
        }
        if (ownerQ.rows[0].owner_id !== userId) {
            return res.status(403).json({ success: false, message: 'Yalnızca restoran sahibi yorumlara yanıt verebilir.' });
        }

        // 2. Yorum bu restorana mı ait?
        const reviewQ = await pool.query(
            'SELECT review_id FROM review WHERE review_id = $1 AND restaurant_id = $2',
            [reviewId, restaurantId]
        );
        if (reviewQ.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Yorum bulunamadı veya bu restorana ait değil.' });
        }

        // 3. Reply ekle (UNIQUE constraint → çift yanıt 409)
        try {
            const { rows } = await pool.query(
                `INSERT INTO review_reply (review_id, user_id, content)
                 VALUES ($1, $2, $3)
                 RETURNING reply_id, review_id, user_id, content, created_at`,
                [reviewId, userId, trimmed]
            );
            return res.status(201).json({ success: true, data: rows[0] });
        } catch (err) {
            if (err.code === '23505') {
                // UNIQUE violation — zaten yanıt verilmiş
                return res.status(409).json({ success: false, message: 'Bu yoruma zaten yanıt verdiniz.' });
            }
            throw err;
        }
    } catch (err) {
        console.error('[addReply]', err.message);
        res.status(500).json({ success: false, message: 'Yanıt kaydedilirken sunucu hatası oluştu.' });
    }
};
