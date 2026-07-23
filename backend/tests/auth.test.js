// Auth controller — kritik akış testleri (login).
// DB ve bcrypt mock'lanır; dış bağımlılık yok, her test izole çalışır.

jest.mock('../config/db', () => ({ query: jest.fn() }));
jest.mock('bcrypt', () => ({
    compare: jest.fn(),
    hash:    jest.fn(),
}));

const pool   = require('../config/db');
const bcrypt = require('bcrypt');
const jwt    = require('jsonwebtoken');
const authController = require('../controllers/authController');

process.env.JWT_SECRET     = 'test-secret-must-be-at-least-32-chars-long';
process.env.JWT_EXPIRES_IN = '1h';

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

beforeEach(() => {
    pool.query.mockReset();
    bcrypt.compare.mockReset();
});

describe('login', () => {
    test('400 — email veya şifre eksikse', async () => {
        const req = { body: { email: '' } };
        const res = mockRes();
        await authController.login(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
        expect(pool.query).not.toHaveBeenCalled();
    });

    test('400 — email/şifre string değilse', async () => {
        const req = { body: { email: 123, password: true } };
        const res = mockRes();
        await authController.login(req, res);
        expect(res.status).toHaveBeenCalledWith(400);
    });

    test('401 — kullanıcı bulunamasa bile dummy bcrypt çalıştırılır (timing attack koruması)', async () => {
        pool.query.mockResolvedValueOnce({ rows: [] });
        bcrypt.compare.mockResolvedValueOnce(false);

        const req = { body: { email: 'yok@x.com', password: 'whatever123' } };
        const res = mockRes();
        await authController.login(req, res);

        expect(bcrypt.compare).toHaveBeenCalledTimes(1);
        expect(res.status).toHaveBeenCalledWith(401);
    });

    test('401 — şifre hatalıysa', async () => {
        pool.query.mockResolvedValueOnce({
            rows: [{ user_id: 1, username: 'a', email: 'a@x.com', role: 'Customer', password_hash: 'h' }],
        });
        bcrypt.compare.mockResolvedValueOnce(false);

        const req = { body: { email: 'a@x.com', password: 'wrongpass' } };
        const res = mockRes();
        await authController.login(req, res);

        expect(res.status).toHaveBeenCalledWith(401);
    });

    test('200 — geçerli login: token döner, password_hash response\'a sızmaz', async () => {
        pool.query.mockResolvedValueOnce({
            rows: [{
                user_id: 42, username: 'gokay', email: 'a@x.com',
                role: 'Customer', password_hash: 'hashed',
            }],
        });
        bcrypt.compare.mockResolvedValueOnce(true);

        const req = { body: { email: 'a@x.com', password: 'correctpass' } };
        const res = mockRes();
        await authController.login(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        const payload = res.json.mock.calls[0][0];
        expect(payload.success).toBe(true);
        expect(payload.token).toEqual(expect.any(String));
        expect(payload.user).toMatchObject({ user_id: 42, email: 'a@x.com', role: 'Customer' });
        // password_hash hiçbir şekilde response'a dahil olmamalı
        expect(JSON.stringify(payload)).not.toContain('password_hash');
        expect(JSON.stringify(payload)).not.toContain('hashed');

        const decoded = jwt.verify(payload.token, process.env.JWT_SECRET);
        expect(decoded.user_id).toBe(42);
        expect(decoded.role).toBe('Customer');
    });

    test('200 — Owner rolü için restaurant_id eklenir', async () => {
        pool.query
            .mockResolvedValueOnce({
                rows: [{
                    user_id: 7, username: 'biz', email: 'biz@x.com',
                    role: 'Owner', password_hash: 'h',
                }],
            })
            .mockResolvedValueOnce({ rows: [{ restaurant_id: 99 }] });
        bcrypt.compare.mockResolvedValueOnce(true);

        const req = { body: { email: 'biz@x.com', password: 'correctpass' } };
        const res = mockRes();
        await authController.login(req, res);

        expect(res.status).toHaveBeenCalledWith(200);
        expect(res.json.mock.calls[0][0].user.restaurant_id).toBe(99);
    });

    test('500 — DB hatası fırlatırsa generic mesaj döner', async () => {
        pool.query.mockRejectedValueOnce(new Error('connection refused'));

        const req = { body: { email: 'a@x.com', password: 'pw' } };
        const res = mockRes();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        await authController.login(req, res);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        const payload = res.json.mock.calls[0][0];
        expect(payload.success).toBe(false);
        // İç hata mesajı sızdırılmamalı
        expect(payload.message).not.toContain('connection refused');
    });
});
