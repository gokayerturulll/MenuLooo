// src/middleware/auth.middleware.js
// JWT token doğrulama middleware'i.
// Korumalı route'lara gelen her istekte token kontrolü yapar.

const jwt = require('jsonwebtoken');
const { query } = require('../../config/database');

/**
 * Korumalı endpoint'lere erişimi kontrol eden middleware.
 *
 * Kullanım:
 * router.get('/profile', authMiddleware, controller.getProfile)
 *
 * iOS tarafı şu başlığı göndermelidir:
 * Authorization: Bearer <token>
 */
const authMiddleware = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Yetkilendirme token\'ı eksik.' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Kullanıcının hâlâ aktif olduğunu doğrula
    const result = await query(
      'SELECT id, name, email, user_type FROM users WHERE id = $1 AND is_active = TRUE',
      [decoded.userId]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Kullanıcı bulunamadı veya hesap devre dışı.' });
    }

    // Kullanıcı bilgisini sonraki handler'a taşı
    req.user = result.rows[0];
    next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token süresi dolmuş. Lütfen tekrar giriş yapın.' });
    }
    return res.status(401).json({ error: 'Geçersiz token.' });
  }
};

/**
 * Sadece işletme sahiplerine izin veren middleware.
 * authMiddleware'den SONRA kullanılmalı.
 */
const businessOnly = (req, res, next) => {
  if (req.user?.user_type !== 'business') {
    return res.status(403).json({ error: 'Bu işlem sadece işletme hesapları için geçerlidir.' });
  }
  next();
};

module.exports = { authMiddleware, businessOnly };
