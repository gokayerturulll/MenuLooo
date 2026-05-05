// src/controllers/auth.controller.js
// Kayıt, giriş ve token yenileme işlemlerinin iş mantığı.

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const { query } = require('../../config/database');

/** JWT token üret */
const generateTokens = (userId) => {
  const accessToken = jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
  const refreshToken = jwt.sign(
    { userId },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d' }
  );
  return { accessToken, refreshToken };
};

/**
 * POST /api/auth/register
 * Yeni kullanıcı kaydı.
 */
exports.register = async (req, res) => {
  try {
    const { name, email, password, user_type } = req.body;

    // E-posta zaten var mı?
    const existing = await query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Bu e-posta zaten kayıtlı.' });
    }

    // Şifreyi hashle (bcrypt, 12 tur)
    const passwordHash = await bcrypt.hash(password, 12);

    // Kullanıcıyı veritabanına ekle
    const result = await query(
      `INSERT INTO users (id, name, email, password_hash, user_type)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, name, email, user_type, created_at`,
      [uuidv4(), name, email, passwordHash, user_type || 'customer']
    );

    const user = result.rows[0];
    const { accessToken, refreshToken } = generateTokens(user.id);

    // Refresh token'ı veritabanına kaydet
    await query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days')`,
      [user.id, refreshToken]
    );

    res.status(201).json({
      message: 'Kayıt başarılı.',
      user: { id: user.id, name: user.name, email: user.email, user_type: user.user_type },
      access_token: accessToken,
      refresh_token: refreshToken
    });
  } catch (err) {
    console.error('Register hatası:', err);
    res.status(500).json({ error: 'Kayıt sırasında hata oluştu.' });
  }
};

/**
 * POST /api/auth/login
 * E-posta + şifre ile giriş.
 */
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const result = await query(
      'SELECT id, name, email, password_hash, user_type, is_active FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'E-posta veya şifre hatalı.' });
    }

    const user = result.rows[0];

    if (!user.is_active) {
      return res.status(403).json({ error: 'Hesabınız devre dışı bırakılmış.' });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'E-posta veya şifre hatalı.' });
    }

    const { accessToken, refreshToken } = generateTokens(user.id);

    await query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days')`,
      [user.id, refreshToken]
    );

    res.json({
      message: 'Giriş başarılı.',
      user: { id: user.id, name: user.name, email: user.email, user_type: user.user_type },
      access_token: accessToken,
      refresh_token: refreshToken
    });
  } catch (err) {
    console.error('Login hatası:', err);
    res.status(500).json({ error: 'Giriş sırasında hata oluştu.' });
  }
};

/**
 * POST /api/auth/refresh
 * Süresi dolmuş access token'ı yenile.
 */
exports.refresh = async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) return res.status(400).json({ error: 'Refresh token gerekli.' });

    const decoded = jwt.verify(refresh_token, process.env.JWT_REFRESH_SECRET);

    // Token veritabanında var mı ve süresi dolmamış mı?
    const tokenResult = await query(
      'SELECT id FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [refresh_token]
    );
    if (tokenResult.rows.length === 0) {
      return res.status(401).json({ error: 'Geçersiz veya süresi dolmuş refresh token.' });
    }

    const { accessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId);

    // Eski token'ı sil, yenisini ekle
    await query('DELETE FROM refresh_tokens WHERE token = $1', [refresh_token]);
    await query(
      `INSERT INTO refresh_tokens (user_id, token, expires_at)
       VALUES ($1, $2, NOW() + INTERVAL '30 days')`,
      [decoded.userId, newRefreshToken]
    );

    res.json({ access_token: accessToken, refresh_token: newRefreshToken });
  } catch (err) {
    res.status(401).json({ error: 'Token yenileme başarısız.' });
  }
};

/**
 * POST /api/auth/logout
 * Çıkış — refresh token'ı geçersiz kıl.
 */
exports.logout = async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (refresh_token) {
      await query('DELETE FROM refresh_tokens WHERE token = $1', [refresh_token]);
    }
    res.json({ message: 'Çıkış başarılı.' });
  } catch (err) {
    res.status(500).json({ error: 'Çıkış sırasında hata oluştu.' });
  }
};
