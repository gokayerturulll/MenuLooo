// middleware/auth.js
// JWT doğrulama ve role-based guard'lar.
//
// authController.js token'ı şu payload ile sign ediyor:
//   { user_id, role }
//
// Kullanım:
//   const { authMiddleware, ownerOnly } = require('../middleware/auth');
//   router.post('/foo', authMiddleware, ownerOnly, controller.handler);

const jwt = require('jsonwebtoken');

/** Bearer token zorunlu — geçerli kullanıcıyı req.user'a yerleştirir. */
exports.authMiddleware = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            success: false,
            message: 'Yetkilendirme token\'ı eksik.'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET || 'fallback_secret_key'
        );
        // { user_id, role, iat, exp }
        req.user = decoded;
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: 'Token süresi dolmuş. Lütfen tekrar giriş yapın.'
            });
        }
        return res.status(401).json({
            success: false,
            message: 'Geçersiz token.'
        });
    }
};

/** Yalnızca işletme rolleri (Owner/Admin/Business) izinli — authMiddleware'den sonra kullan. */
exports.ownerOnly = (req, res, next) => {
    const role = String(req.user?.role || '').toLowerCase();
    const allowed = ['owner', 'admin', 'business'];

    if (!allowed.includes(role)) {
        return res.status(403).json({
            success: false,
            message: 'Bu işlem yalnızca işletme hesapları için geçerlidir.'
        });
    }
    next();
};
