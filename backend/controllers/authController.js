const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
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
