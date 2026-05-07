const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

exports.register = async (req, res) => {
    try {
        const { username, email, password, role } = req.body;
        
        // Gerekli alanların kontrolü
        if (!username || !email || !password) {
            return res.status(400).json({ success: false, message: 'Lütfen kullanıcı adı, email ve şifre giriniz.' });
        }
        
        // Kullanıcı daha önce kayıtlı mı?
        const userCheck = await pool.query('SELECT * FROM "user" WHERE email = $1', [email]);
        if (userCheck.rows.length > 0) {
            return res.status(400).json({ success: false, message: 'Bu email adresi zaten kullanılıyor.' });
        }
        
        // Şifreyi hash'le
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // DB'ye kaydet
        const result = await pool.query(
            'INSERT INTO "user" (username, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING user_id, username, email, role',
            [username, email, hashedPassword, role || 'Customer']
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

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        if (!email || !password) {
            return res.status(400).json({ success: false, message: 'Lütfen email ve şifrenizi giriniz.' });
        }

        // Kullanıcıyı bul
        const result = await pool.query('SELECT * FROM "user" WHERE email = $1', [email]);
        if (result.rows.length === 0) {
            return res.status(401).json({ success: false, message: 'E-posta veya şifre hatalı.' });
        }
        
        const user = result.rows[0];
        
        // Şifre kontrolü (Eski mock veriler için 'test' şifresiyle geçici giriş izni)
        let isMatch = false;
        if (user.password_hash === 'hash_placeholder' && password === 'test') {
            isMatch = true;
        } else {
            isMatch = await bcrypt.compare(password, user.password_hash);
        }
        
        if (!isMatch) {
            return res.status(401).json({ success: false, message: 'E-posta veya şifre hatalı.' });
        }
        
        // JWT Oluştur
        const token = jwt.sign(
            { user_id: user.user_id, role: user.role },
            process.env.JWT_SECRET || 'fallback_secret_key',
            { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
        );

        // İşletme rollerinde sahibi olduğu restoranı response'a ekle.
        // iOS tarafında User.restaurantId bu alanı bekliyor; nil değil number gelirse
        // MenuManagerView doğru restoranın menüsünü çeker.
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
