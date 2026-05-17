const pool = require('../config/db');

// @parse/node-apn paketi opsiyonel — kurulu değilse push devre dışı kalır.
// Kurmak için: npm install @parse/node-apn
let apn = null;
try {
    apn = require('@parse/node-apn');
} catch {
    console.warn('[APNs] "@parse/node-apn" paketi bulunamadı. Push bildirimleri devre dışı. `npm install @parse/node-apn` ile kurun.');
}

// ─── APNs Provider (lazy singleton) ─────────────────────────────────────────

let _provider = null;

function getProvider() {
    if (_provider) return _provider;
    if (!apn) return null;

    const keyPath = process.env.APN_KEY_PATH;
    const keyId   = process.env.APN_KEY_ID;
    const teamId  = process.env.APN_TEAM_ID;

    if (!keyPath || !keyId || !teamId) {
        console.warn('[APNs] APN_KEY_PATH, APN_KEY_ID veya APN_TEAM_ID eksik — push devre dışı.');
        return null;
    }

    const path = require('path');
    _provider = new apn.Provider({
        token: {
            key:    path.resolve(keyPath),
            keyId,
            teamId,
        },
        production: process.env.NODE_ENV === 'production',
    });

    return _provider;
}

// ─── POST /api/notifications/register ────────────────────────────────────────

exports.registerToken = async (req, res) => {
    try {
        const userId = req.user.user_id;
        const { device_token, platform = 'ios' } = req.body;

        if (!device_token || typeof device_token !== 'string') {
            return res.status(400).json({ success: false, message: 'device_token zorunludur.' });
        }
        if (device_token.length < 32 || device_token.length > 200) {
            return res.status(400).json({ success: false, message: 'Geçersiz device_token formatı.' });
        }

        await pool.query(
            `INSERT INTO push_token (user_id, device_token, platform, updated_at)
             VALUES ($1, $2, $3, NOW())
             ON CONFLICT (user_id, device_token) DO UPDATE SET updated_at = NOW()`,
            [userId, device_token, platform]
        );

        res.status(200).json({ success: true, message: 'Cihaz token kaydedildi.' });
    } catch (err) {
        console.error('[registerToken]', err.message);
        res.status(500).json({ success: false, message: 'Token kaydedilemedi.' });
    }
};

// ─── Push Gönderme Yardımcısı ─────────────────────────────────────────────────
// Diğer controller'lardan (örn. roomController) çağrılır.

/**
 * Bir kullanıcıya APNs push bildirimi gönderir (fire-and-forget).
 * @param {number} userId
 * @param {{ title: string, body: string, deepLink: string, extra?: object }} opts
 */
exports.sendPushToUser = async (userId, { title, body, deepLink, extra = {} }) => {
    const provider = getProvider();
    if (!provider) return;

    try {
        const { rows } = await pool.query(
            'SELECT device_token FROM push_token WHERE user_id = $1 AND platform = $2',
            [userId, 'ios']
        );
        if (rows.length === 0) return;

        const bundleId = process.env.APN_BUNDLE_ID || 'com.menulo.app';

        for (const { device_token } of rows) {
            const note       = new apn.Notification();
            note.expiry      = Math.floor(Date.now() / 1000) + 3600;
            note.badge       = 1;
            note.sound       = 'default';
            note.alert       = { title, body };
            note.topic       = bundleId;
            note.payload     = { deep_link: deepLink, ...extra };

            provider.send(note, device_token).then(result => {
                if (result.failed.length > 0) {
                    const reason = result.failed[0].response?.reason;
                    console.warn('[APNs] Gönderim hatası:', reason);
                    // Geçersiz token'ı DB'den temizle
                    if (reason === 'BadDeviceToken' || reason === 'Unregistered') {
                        pool.query('DELETE FROM push_token WHERE device_token = $1', [device_token]).catch(() => {});
                    }
                }
            });
        }
    } catch (err) {
        console.error('[sendPushToUser]', err.message);
    }
};

// ─── Deep Link Üretici Yardımcılar ───────────────────────────────────────────

exports.generateRoomDeepLink       = (pinCode)      => `menulo://room/${pinCode}`;
exports.generateRestaurantDeepLink = (restaurantId) => `menulo://restaurant/${restaurantId}`;
