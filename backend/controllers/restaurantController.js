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
                            'price', mi.price,
                            'description', mi.description,
                            'image_url', mi.image_url,
                            'dietary_tags', mi.dietary_tags
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
                menu_id: menuId,
                restaurant_id: id,
                categories: categoriesResult.rows
            }
        });
    } catch (error) {
        console.error('Get Menu Error:', error);
        res.status(500).json({ success: false, message: 'Menü getirilirken sunucu hatası oluştu.' });
    }
};
