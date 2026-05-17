const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../config/db');

// ─── Validation helpers ───────────────────────────────────────────────────────

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const USERNAME_MAX = 50;
const PASSWORD_MIN = 8;
const PASSWORD_MAX = 128;

function validateRegisterInput({ username, email, password }) {
    if (!username || !email || !password) {
        return 'Kullanıcı adı, email ve şifre zorunludur.';
    }
    if (typeof username !== 'string' || username.trim().length === 0) {
        return 'Geçersiz kullanıcı adı.';
    }
    if (username.trim().length > USERNAME_MAX) {
        return `Kullanıcı adı en fazla ${USERNAME_MAX} karakter olabilir.`;
    }
    if (!EMAIL_REGEX.test(email)) {
        return 'Geçerli bir email adresi giriniz.';
    }
    if (typeof password !== 'string' || password.length < PASSWORD_MIN) {
        return `Şifre en az ${PASSWORD_MIN} karakter olmalıdır.`;
    }
    if (password.length > PASSWORD_MAX) {
        return `Şifre en fazla ${PASSWORD_MAX} karakter olabilir.`;
    }
    return null;
}

// ─── Register ─────────────────────────────────────────────────────────────────

exports.register = async (req, res) => {
    try {
        const { username, email, password, role: rawRole } = req.body;

        const validationError = validateRegisterInput({ username, email, password });
        if (validationError) {
            return res.status(400).json({ success: false, message: validationError });
        }

        const ALLOWED_REGISTER_ROLES = ['Customer', 'Owner'];
        const role = ALLOWED_REGISTER_ROLES.includes(rawRole) ? rawRole : 'Customer';

        const userCheck = await pool.query(
            'SELECT user_id FROM "user" WHERE email = $1',
            [email.toLowerCase().trim()]
        );
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ success: false, message: 'Bu email adresi zaten kullanılıyor.' });
        }

        const hashedPassword = await bcrypt.hash(password, 12);

        const result = await pool.query(
            'INSERT INTO "user" (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING user_id, username, email, role',
            [username.trim(), email.toLowerCase().trim(), hashedPassword, role]
        );

        res.status(201).json({
            success: true,
            message: 'Kullanıcı başarıyla oluşturuldu.',
            data: result.rows[0]
        });
    } catch (error) {
        console.error('Register Error:', error);
        res.status(500).json({ success: false, message: 'Kayıt olurken bir sunucu hatası oluştu.' });
    }
};

// ─── Login ────────────────────────────────────────────────────────────────────

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Email ve şifre zorunludur.' });
        }
        if (typeof email !== 'string' || typeof password !== 'string') {
            return res.status(400).json({ success: false, message: 'Geçersiz istek formatı.' });
        }

        const result = await pool.query(
            'SELECT * FROM "user" WHERE email = $1',
            [email.toLowerCase().trim()]
        );
        if (result.rows.length === 0) {
            // Timing attack'i önlemek için kullanıcı yok olsa bile hash işlemi yap
            await bcrypt.compare(password, '$2b$12$invalidhashpadding000000000000000000000000000000000000');
            return res.status(401).json({ success: false, message: 'E-posta veya şifre hatalı.' });
        }

        const user = result.rows[0];
        const isMatch = await bcrypt.compare(password, user.password_hash);

        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'E-posta veya şifre hatalı.' });
        }

        if (!process.env.JWT_SECRET) {
            console.error('[FATAL] JWT_SECRET is not set — refusing to sign token.');
            return res.status(500).json({ success: false, message: 'Sunucu yapılandırma hatası.' });
        }

        const token = jwt.sign(
            { user_id: user.user_id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        const businessRoles = ['owner', 'admin', 'business'];
        let restaurantId = null;
        if (user.role && businessRoles.includes(String(user.role).toLowerCase())) {
            const ownedRestaurant = await pool.query(
                'SELECT restaurant_id FROM restaurant WHERE owner_id = $1 ORDER BY restaurant_id ASC LIMIT 1',
                [user.user_id]
            );
            if (ownedRestaurant.rows.length > 0) {
                restaurantId = ownedRestaurant.rows[0].restaurant_id;
            }
        }

        res.status(200).json({
            success: true,
            message: 'Giriş başarılı.',
            token,
            user: {
                user_id: user.user_id,
                username: user.username,
                email: user.email,
                role: user.role,
                restaurant_id: restaurantId
            }
        });
    } catch (error) {
        console.error('Login Error:', error);
        res.status(500).json({ success: false, message: 'Giriş yaparken bir sunucu hatası oluştu.' });
    }
};

// ─── Forgot Password ──────────────────────────────────────────────────────
// 1. Email ile kullanıcıyı bul (yoksa bile aynı cevabı dön → enum saldırısı önle).
// 2. 32 byte random token üret; hash'ini DB'ye yaz, 1 saat geçerli.
// 3. Ham token'ı email ile gönder (production: SendGrid/Mailgun; dev: console.log).
// 4. Response her zaman 200 OK + generic mesaj — kullanıcı varlığını ifşa etme.

const RESET_TOKEN_TTL_MS = 60 * 60 * 1000;          // 1 saat

exports.forgotPassword = async (req, res) => {
    try {
        const { email } = req.body;
        if (!email || typeof email !== 'string' || !EMAIL_REGEX.test(email)) {
            return res.status(400).json({ success: false, message: 'Geçerli bir email adresi giriniz.' });
        }

        const normalized = email.toLowerCase().trim();
        const userQ = await pool.query(
            'SELECT user_id FROM "user" WHERE email = $1',
            [normalized]
        );

        // Generic response — kullanıcı var/yok ifşa etme
        const genericResponse = {
            success: true,
            message: 'Eğer bu email kayıtlıysa, şifre sıfırlama bağlantısı gönderildi.'
        };

        if (userQ.rows.length === 0) {
            return res.status(200).json(genericResponse);
        }

        const userId = userQ.rows[0].user_id;

        // 32 byte random token → 64 hex karakter
        const rawToken  = crypto.randomBytes(32).toString('hex');
        const tokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
        const expiresAt = new Date(Date.now() + RESET_TOKEN_TTL_MS);

        await pool.query(
            `INSERT INTO password_reset_token (user_id, token_hash, expires_at)
             VALUES ($1, $2, $3)`,
            [userId, tokenHash, expiresAt]
        );

        // PLACEHOLDER: gerçek email entegrasyonu yapılana kadar console'a yazılıyor
        // Production'da: SendGrid / Mailgun / Amazon SES ile email at
        const resetLink = `${process.env.APP_URL || 'menulo://'}reset-password?token=${rawToken}`;
        console.log(`[forgotPassword] Email: ${normalized} | Reset link: ${resetLink}`);

        return res.status(200).json(genericResponse);
    } catch (error) {
        console.error('[forgotPassword]', error.message);
        res.status(500).json({ success: false, message: 'Sunucu hatası oluştu.' });
    }
};

// ─── Reset Password ───────────────────────────────────────────────────────
// Ham token + yeni şifre alır; token'ı hash'leyip DB'de geçerli kayıt arar.
// Başarılıysa şifreyi günceller ve token'ı `used_at` ile invalidate eder.

exports.resetPassword = async (req, res) => {
    try {
        const { token, newPassword } = req.body;

        if (!token || typeof token !== 'string' || token.length !== 64) {
            return res.status(400).json({ success: false, message: 'Geçersiz token.' });
        }
        if (!newPassword || typeof newPassword !== 'string' ||
            newPassword.length < PASSWORD_MIN || newPassword.length > PASSWORD_MAX) {
            return res.status(400).json({
                success: false,
                message: `Şifre ${PASSWORD_MIN}-${PASSWORD_MAX} karakter arasında olmalıdır.`
            });
        }

        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');

        // Atomik kontrol: token geçerli mi, expire olmuş mu, kullanılmış mı?
        const tokenQ = await pool.query(
            `SELECT token_id, user_id
             FROM password_reset_token
             WHERE token_hash = $1
               AND used_at IS NULL
               AND expires_at > NOW()`,
            [tokenHash]
        );
        if (tokenQ.rows.length === 0) {
            return res.status(400).json({ success: false, message: 'Token geçersiz veya süresi dolmuş.' });
        }

        const { token_id, user_id } = tokenQ.rows[0];
        const hashedPassword = await bcrypt.hash(newPassword, 12);

        // Transaction: şifre güncelle + token'ı invalidate et
        const client = await pool.connect();
        try {
            await client.query('BEGIN');
            await client.query(
                'UPDATE "user" SET password_hash = $1 WHERE user_id = $2',
                [hashedPassword, user_id]
            );
            await client.query(
                'UPDATE password_reset_token SET used_at = NOW() WHERE token_id = $1',
                [token_id]
            );
            await client.query('COMMIT');
        } catch (err) {
            await client.query('ROLLBACK');
            throw err;
        } finally {
            client.release();
        }

        return res.status(200).json({ success: true, message: 'Şifreniz başarıyla güncellendi.' });
    } catch (error) {
        console.error('[resetPassword]', error.message);
        res.status(500).json({ success: false, message: 'Şifre sıfırlanırken sunucu hatası oluştu.' });
    }
};

// ─── Change Password (authenticated) ──────────────────────────────────────
// Mevcut şifresini bilen kullanıcı kendi şifresini değiştirir.

exports.changePassword = async (req, res) => {
    try {
        const userId = req.user.user_id;
        const { oldPassword, newPassword } = req.body;

        if (!oldPassword || !newPassword ||
            typeof oldPassword !== 'string' || typeof newPassword !== 'string') {
            return res.status(400).json({ success: false, message: 'Eski ve yeni şifre zorunludur.' });
        }
        if (newPassword.length < PASSWORD_MIN || newPassword.length > PASSWORD_MAX) {
            return res.status(400).json({
                success: false,
                message: `Yeni şifre ${PASSWORD_MIN}-${PASSWORD_MAX} karakter arasında olmalıdır.`
            });
        }
        if (oldPassword === newPassword) {
            return res.status(400).json({ success: false, message: 'Yeni şifre eski şifre ile aynı olamaz.' });
        }

        const userQ = await pool.query(
            'SELECT password_hash FROM "user" WHERE user_id = $1',
            [userId]
        );
        if (userQ.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }

        const isMatch = await bcrypt.compare(oldPassword, userQ.rows[0].password_hash);
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'Mevcut şifreniz hatalı.' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 12);
        await pool.query(
            'UPDATE "user" SET password_hash = $1 WHERE user_id = $2',
            [hashedPassword, userId]
        );

        return res.status(200).json({ success: true, message: 'Şifreniz başarıyla değiştirildi.' });
    } catch (error) {
        console.error('[changePassword]', error.message);
        res.status(500).json({ success: false, message: 'Şifre değiştirilirken sunucu hatası oluştu.' });
    }
};

// ─── User Stats ───────────────────────────────────────────────────────────────

exports.getUserStats = async (req, res) => {
    try {
        const userId = req.user.user_id;

        // Favori sayısı
        const favResult = await pool.query(
            'SELECT COUNT(*)::int AS fav_count FROM favorite WHERE user_id = $1',
            [userId]
        );

        // Yorum sayısı (ziyaret proxy'si) + ortalama kullanıcı puanı
        const reviewResult = await pool.query(`
            SELECT
                COUNT(*)::int                                                        AS review_count,
                COALESCE(
                    ROUND(AVG(
                        NULLIF((rating_taste + rating_service + rating_attitude) / 3.0, 0)
                    )::numeric, 1),
                    0.0
                )::double precision                                                  AS avg_rating
            FROM review
            WHERE user_id = $1
        `, [userId]);

        const stats = {
            visit_count:    reviewResult.rows[0].review_count,
            favourite_count: favResult.rows[0].fav_count,
            avg_rating:     reviewResult.rows[0].avg_rating,
        };

        // İşletme sahibiyse restoran istatistiklerini de ekle
        const businessRoles = ['owner', 'admin', 'business'];
        if (businessRoles.includes(String(req.user.role).toLowerCase())) {
            const bizResult = await pool.query(`
                SELECT
                    r.restaurant_id,
                    COALESCE(
                        ROUND(AVG(
                            NULLIF((rv.rating_taste + rv.rating_service + rv.rating_attitude) / 3.0, 0)
                        )::numeric, 1),
                        0.0
                    )::double precision  AS avg_rating,
                    COUNT(rv.review_id)::int AS review_count,
                    COUNT(DISTINCT f.favorite_id)::int AS fav_count
                FROM restaurant r
                LEFT JOIN review rv   ON r.restaurant_id = rv.restaurant_id
                LEFT JOIN favorite f  ON r.restaurant_id = f.target_id AND f.type = 'Restaurant'
                WHERE r.owner_id = $1
                GROUP BY r.restaurant_id
                ORDER BY r.restaurant_id ASC
                LIMIT 1
            `, [userId]);

            if (bizResult.rows.length > 0) {
                const biz = bizResult.rows[0];
                stats.business = {
                    restaurant_id: biz.restaurant_id,
                    avg_rating:    biz.avg_rating,
                    review_count:  biz.review_count,
                    fav_count:     biz.fav_count,
                };
            }
        }

        res.status(200).json({ success: true, data: stats });
    } catch (error) {
        console.error('[getUserStats]', error.message);
        res.status(500).json({ success: false, message: 'İstatistikler alınamadı.' });
    }
};

// ─── Delete Account (GDPR "right to be forgotten") ────────────────────────

exports.deleteAccount = async (req, res) => {
    try {
        const userId = req.user.user_id;

        // Cascade: room_member, review, search_analytics, favorites otomatik silinir
        // (ON DELETE CASCADE migrations/001'de tanımlı)
        const result = await pool.query(
            'DELETE FROM "user" WHERE user_id = $1 RETURNING user_id',
            [userId]
        );

        if (result.rowCount === 0) {
            return res.status(404).json({ success: false, message: 'Kullanıcı bulunamadı.' });
        }

        return res.status(200).json({
            success: true,
            message: 'Hesabınız ve tüm verileriniz kalıcı olarak silindi.'
        });
    } catch (error) {
        console.error('[deleteAccount]', error.message);
        res.status(500).json({ success: false, message: 'Hesap silinirken sunucu hatası oluştu.' });
    }
};
