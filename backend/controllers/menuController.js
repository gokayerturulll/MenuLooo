const pool = require('../config/db');

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
