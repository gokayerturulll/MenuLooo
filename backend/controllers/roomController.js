const pool = require('../config/db');

exports.joinRoom = async (req, res) => {
    try {
        // user_id normalde JWT auth middleware üzerinden req.user'dan gelir,
        // şimdilik test kolaylığı için body'den alıyoruz.
        const { qr_code, user_id, individual_preferences } = req.body;
        
        if (!qr_code || !user_id) {
            return res.status(400).json({ success: false, message: 'qr_code ve user_id bilgileri zorunludur.' });
        }
        
        // QR koda ait odayı bul
        const roomResult = await pool.query('SELECT room_id FROM friend_room WHERE qr_code = $1', [qr_code]);
        if (roomResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Geçersiz QR kod, oda bulunamadı.' });
        }
        const roomId = roomResult.rows[0].room_id;
        
        // Kullanıcı bu odaya daha önce katılmış mı?
        const memberCheck = await pool.query('SELECT * FROM room_member WHERE room_id = $1 AND user_id = $2', [roomId, user_id]);
        if (memberCheck.rows.length > 0) {
            return res.status(400).json({ success: false, message: 'Bu odaya zaten katıldınız.' });
        }
        
        // Tercihleri (JSON) string formatına çevir
        const prefsStr = typeof individual_preferences === 'object' ? JSON.stringify(individual_preferences) : individual_preferences;
        
        // Odaya ekle
        await pool.query(
            'INSERT INTO room_member (room_id, user_id, individual_preferences) VALUES ($1, $2, $3)',
            [roomId, user_id, prefsStr]
        );
        
        res.status(201).json({
            success: true,
            message: 'Odaya başarıyla katıldınız.',
            data: { room_id: roomId, user_id }
        });
    } catch (error) {
        console.error('Join Room Error:', error);
        res.status(500).json({ success: false, message: 'Odaya katılırken sunucu hatası oluştu.' });
    }
};
