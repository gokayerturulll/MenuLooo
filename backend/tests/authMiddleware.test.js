// middleware/auth.js — JWT guard ve rol kontrolü testleri.
//
// Bu middleware korumalı TÜM endpoint'lerin önünden geçtiği için buradaki bir
// regresyon (örn. jwt.verify → jwt.decode) tüm API'yi yetkisiz erişime açar.
// Bu yüzden imza doğrulama ve alg=none gibi saldırı yolları da test edilir.

const jwt = require('jsonwebtoken');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

const SECRET = 'test-secret-must-be-at-least-32-chars-long';

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

function mockReq(authHeader) {
    return { headers: authHeader ? { authorization: authHeader } : {} };
}

beforeEach(() => {
    process.env.JWT_SECRET = SECRET;
});

describe('authMiddleware — token yokluğu', () => {
    test('401 — Authorization header hiç yoksa', () => {
        const req = mockReq(null);
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(req, res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
        expect(req.user).toBeUndefined();
    });

    test('401 — şema "Bearer " değilse (örn. Basic)', () => {
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq('Basic dXNlcjpwYXNz'), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    test('401 — sadece "Bearer" yazıp token verilmezse', () => {
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq('Bearer '), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });
});

describe('authMiddleware — token doğrulama', () => {
    test('200 — geçerli token: req.user doldurulur ve next() çağrılır', () => {
        const token = jwt.sign({ user_id: 42, role: 'Customer' }, SECRET, { expiresIn: '1h' });
        const req = mockReq(`Bearer ${token}`);
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(req, res, next);

        expect(next).toHaveBeenCalledTimes(1);
        expect(res.status).not.toHaveBeenCalled();
        expect(req.user.user_id).toBe(42);
        expect(req.user.role).toBe('Customer');
    });

    test('401 — token BAŞKA bir secret ile imzalanmışsa (imza doğrulanmalı)', () => {
        const token = jwt.sign({ user_id: 1, role: 'Owner' }, 'baska-bir-secret-32-karakterden-uzun');
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq(`Bearer ${token}`), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    test('401 — alg=none saldırısı reddedilmeli', () => {
        // İmzasız token: header alg "none", signature boş.
        const header  = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
        const payload = Buffer.from(JSON.stringify({ user_id: 1, role: 'Admin' })).toString('base64url');
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq(`Bearer ${header}.${payload}.`), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    test('401 — süresi dolmuş token', () => {
        const token = jwt.sign({ user_id: 5, role: 'Customer' }, SECRET, { expiresIn: '-1s' });
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq(`Bearer ${token}`), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(res.json.mock.calls[0][0].message).toMatch(/süresi dolmuş/i);
        expect(next).not.toHaveBeenCalled();
    });

    test('401 — tamamen bozuk token', () => {
        const res = mockRes();
        const next = jest.fn();

        authMiddleware(mockReq('Bearer not-a-real-jwt'), res, next);

        expect(res.status).toHaveBeenCalledWith(401);
        expect(next).not.toHaveBeenCalled();
    });

    test('500 — JWT_SECRET tanımsızsa token doğrulanmadan reddedilir', () => {
        delete process.env.JWT_SECRET;
        const token = jwt.sign({ user_id: 1, role: 'Customer' }, SECRET);
        const res = mockRes();
        const next = jest.fn();

        const errSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        authMiddleware(mockReq(`Bearer ${token}`), res, next);
        errSpy.mockRestore();

        expect(res.status).toHaveBeenCalledWith(500);
        expect(next).not.toHaveBeenCalled();
    });
});

describe('ownerOnly — rol kontrolü', () => {
    test.each(['Owner', 'owner', 'ADMIN', 'Business'])(
        'next() — "%s" rolü işletme sayılır (case-insensitive)',
        (role) => {
            const req = { user: { user_id: 1, role } };
            const res = mockRes();
            const next = jest.fn();

            ownerOnly(req, res, next);

            expect(next).toHaveBeenCalledTimes(1);
            expect(res.status).not.toHaveBeenCalled();
        },
    );

    test('403 — Customer rolü işletme endpoint\'ine giremez', () => {
        const res = mockRes();
        const next = jest.fn();

        ownerOnly({ user: { user_id: 1, role: 'Customer' } }, res, next);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(next).not.toHaveBeenCalled();
    });

    test('403 — req.user hiç yoksa (authMiddleware atlanmışsa) çökmeden reddeder', () => {
        const res = mockRes();
        const next = jest.fn();

        ownerOnly({}, res, next);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(next).not.toHaveBeenCalled();
    });

    test('403 — rol alanı boş string ise', () => {
        const res = mockRes();
        const next = jest.fn();

        ownerOnly({ user: { user_id: 1, role: '' } }, res, next);

        expect(res.status).toHaveBeenCalledWith(403);
        expect(next).not.toHaveBeenCalled();
    });
});
