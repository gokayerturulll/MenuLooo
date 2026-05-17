// controllers/userController.js
//   GET /api/users/me  — kimliği doğrulanmış kullanıcının profilini döner
//   PUT /api/users/me  — username ve phone_number güncellemesine izin verir

const pool = require('../config/db');

const USERNAME_MAX = 50;
const PHONE_REGEX  = /^\+?[\d\s\-(). ]{7,20}$/;

exports.getMe = async (req, res) => {
    try {
        const userId = req.user.user_id;
        const { rows } = await pool.query(
            `SELECT user_id, username, email, role, phone_number, created_at
             FROM "user" WHERE user_id = $1`,
            [userId]
        );
        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }
        res.status(200).json({ success: true, data: rows[0] });
    } catch (error) {
        console.error('[getMe]', error.message);
        res.status(500).json({ success: false, message: 'Profil bilgileri alınamadı.' });
    }
};

exports.updateMe = async (req, res) => {
    try {
        const userId = req.user.user_id;
        const { username, phone_number } = req.body;

        if (username !== undefined) {
            if (typeof username !== 'string' ||
                username.trim().length === 0 ||
                username.trim().length > USERNAME_MAX) {
                return res.status(400).json({
                    success: false,
                    message: `Kullanıcı adı 1-${USERNAME_MAX} karakter arasında olmalıdır.`
                });
            }
        }

        if (phone_number !== undefined && phone_number !== null) {
            if (typeof phone_number !== 'string' || !PHONE_REGEX.test(phone_number)) {
                return res.status(400).json({
                    success: false,
                    message: 'Geçerli bir telefon numarası giriniz.'
                });
            }
        }

        const { rows } = await pool.query(
            `UPDATE "user"
             SET username     = COALESCE($1, username),
                 phone_number = COALESCE($2, phone_number)
             WHERE user_id = $3
             RETURNING user_id, username, email, role, phone_number, created_at`,
            [username?.trim() ?? null, phone_number ?? null, userId]
        );

        if (rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }
        res.status(200).json({ success: true, data: rows[0] });
    } catch (error) {
        console.error('[updateMe]', error.message);
        res.status(500).json({ success: false, message: 'Profil güncellenirken sunucu hatası oluştu.' });
    }
};
