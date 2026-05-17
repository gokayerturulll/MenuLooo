// controllers/analyticsController.js
//   GET /api/analytics/searches — en çok aranan sorguları döner
//   Sadece kimliği doğrulanmış kullanıcılar erişebilir.

const pool = require('../config/db');

exports.getTopSearches = async (req, res) => {
    try {
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);

        const { rows } = await pool.query(
            `SELECT
                 query_text,
                 COUNT(*)::int                                    AS search_count,
                 SUM(CASE WHEN is_miss THEN 1 ELSE 0 END)::int   AS miss_count,
                 MAX(created_at)                                  AS last_searched_at
             FROM search_analytics
             GROUP BY query_text
             ORDER BY search_count DESC
             LIMIT $1`,
            [limit]
        );

        res.status(200).json({ success: true, count: rows.length, data: rows });
    } catch (error) {
        console.error('[getTopSearches]', error.message);
        res.status(500).json({ success: false, message: 'Arama istatistikleri alınamadı.' });
    }
};
