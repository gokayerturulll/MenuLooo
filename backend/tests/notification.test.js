// notificationController — cihaz token kaydı ve APNs push gönderimi.
//
// Kritik davranışlar:
//  • Push YAN ETKİ olmalı: APNs yapılandırılmamışsa ya da gönderim patlarsa
//    çağıran akış (örn. odaya katılma) etkilenmemeli. sendPushToUser hiçbir
//    koşulda throw etmemeli — bu dosyanın asıl konusu bu.
//  • Geçersiz token temizliği: BadDeviceToken/Unregistered dönen token DB'den
//    silinmeli, yoksa ölü token'lar sonsuza dek denenir.
//  • token uzunluk sınırları DB'ye gitmeden uygulanmalı.
//
// APNs sağlayıcısı modül seviyesinde tekil (singleton) tutulduğu için testler
// arasında jest.resetModules() ile sıfırlanıyor; aksi halde bir testte kurulan
// provider diğerine sızar.

const mockQuery = jest.fn();
jest.mock('../config/db', () => ({ query: mockQuery }));

const mockSend = jest.fn();
jest.mock('@parse/node-apn', () => ({
    Provider:     jest.fn().mockImplementation(() => ({ send: mockSend })),
    Notification: jest.fn().mockImplementation(function () { this.payload = {}; }),
}));

function mockRes() {
    const res = {};
    res.status = jest.fn().mockReturnValue(res);
    res.json   = jest.fn().mockReturnValue(res);
    return res;
}

// APNs env değişkenleriyle birlikte controller'ı taze yükler.
// apnYapilandir=false → getProvider() null döner, push devre dışı kalır.
function yukle({ apnYapilandir = true } = {}) {
    jest.resetModules();
    if (apnYapilandir) {
        process.env.APN_KEY_PATH = '/tmp/AuthKey.p8';
        process.env.APN_KEY_ID   = 'KEY123';
        process.env.APN_TEAM_ID  = 'TEAM123';
    } else {
        delete process.env.APN_KEY_PATH;
        delete process.env.APN_KEY_ID;
        delete process.env.APN_TEAM_ID;
    }
    return require('../controllers/notificationController');
}

// provider.send(...).then(...) fire-and-forget çağrılıyor; mikrotask kuyruğunun
// boşalmasını beklemeden temizlik sorgusu henüz çalışmamış olur.
const tickBekle = () => new Promise((resolve) => { setImmediate(resolve); });

beforeEach(() => {
    mockQuery.mockReset();
    mockSend.mockReset();
    jest.spyOn(console, 'error').mockImplementation(() => {});
    jest.spyOn(console, 'warn').mockImplementation(() => {});
});

afterEach(() => {
    console.error.mockRestore();
    console.warn.mockRestore();
});

// ─── registerToken ──────────────────────────────────────────────────────────

describe('registerToken', () => {
    const GECERLI_TOKEN = 'a'.repeat(64);
    const req = (body) => ({ body, user: { user_id: 7 } });

    test.each([
        ['token yok',        {}],
        ['token null',       { device_token: null }],
        ['token boş string', { device_token: '' }],
        ['token string değil', { device_token: 12345 }],
    ])('400 — %s', async (_ad, body) => {
        const notifications = yukle();
        const res = mockRes();

        await notifications.registerToken(req(body), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(mockQuery).not.toHaveBeenCalled();
    });

    test.each([
        ['31 karakter (çok kısa)',  'a'.repeat(31)],
        ['201 karakter (çok uzun)', 'a'.repeat(201)],
    ])('400 — %s', async (_ad, device_token) => {
        const notifications = yukle();
        const res = mockRes();

        await notifications.registerToken(req({ device_token }), res);

        expect(res.status).toHaveBeenCalledWith(400);
        expect(mockQuery).not.toHaveBeenCalled();
    });

    test.each([
        ['alt sınır 32',  'a'.repeat(32)],
        ['üst sınır 200', 'a'.repeat(200)],
    ])('sınır değeri kabul edilir — %s', async (_ad, device_token) => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({});
        const res = mockRes();

        await notifications.registerToken(req({ device_token }), res);

        expect(res.status).toHaveBeenCalledWith(200);
    });

    test('200 — token kaydedilir, platform varsayılanı ios', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({});
        const res = mockRes();

        await notifications.registerToken(req({ device_token: GECERLI_TOKEN }), res);

        expect(mockQuery).toHaveBeenCalledWith(
            expect.stringContaining('INSERT INTO push_token'),
            [7, GECERLI_TOKEN, 'ios']
        );
        expect(res.status).toHaveBeenCalledWith(200);
    });

    test('platform gövdeden geçersizse bile açıkça verilen değer kullanılır', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({});

        await notifications.registerToken(
            req({ device_token: GECERLI_TOKEN, platform: 'android' }), mockRes()
        );

        expect(mockQuery.mock.calls[0][1][2]).toBe('android');
    });

    test('aynı token tekrar gönderilince ON CONFLICT ile güncellenir', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({});

        await notifications.registerToken(req({ device_token: GECERLI_TOKEN }), mockRes());

        expect(mockQuery.mock.calls[0][0]).toMatch(/ON CONFLICT[\s\S]*DO UPDATE/);
    });

    test('500 — DB hatası dışarı sızmaz', async () => {
        const notifications = yukle();
        mockQuery.mockRejectedValueOnce(new Error('push_token tablosu yok'));
        const res = mockRes();

        await notifications.registerToken(req({ device_token: GECERLI_TOKEN }), res);

        expect(res.status).toHaveBeenCalledWith(500);
        expect(res.json.mock.calls[0][0].message).not.toMatch(/push_token tablosu/);
    });
});

// ─── sendPushToUser ─────────────────────────────────────────────────────────

describe('sendPushToUser', () => {
    const OPTS = { title: 'Oda daveti', body: 'Katıl!', deepLink: 'menulo://room/ABC123' };

    test('APNs yapılandırılmamışsa sessizce çıkar — DB\'ye bile gitmez', async () => {
        const notifications = yukle({ apnYapilandir: false });

        await notifications.sendPushToUser(7, OPTS);

        expect(mockQuery).not.toHaveBeenCalled();
        expect(mockSend).not.toHaveBeenCalled();
    });

    test('kullanıcının kayıtlı token\'ı yoksa gönderim denenmez', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({ rows: [] });

        await notifications.sendPushToUser(7, OPTS);

        expect(mockSend).not.toHaveBeenCalled();
    });

    test('kayıtlı her token için ayrı gönderim yapılır', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({
            rows: [{ device_token: 'tok-1' }, { device_token: 'tok-2' }],
        });
        mockSend.mockResolvedValue({ failed: [] });

        await notifications.sendPushToUser(7, OPTS);
        await tickBekle();

        expect(mockSend).toHaveBeenCalledTimes(2);
        expect(mockSend.mock.calls.map((c) => c[1])).toEqual(['tok-1', 'tok-2']);
    });

    test('bildirim gövdesi deep link ve ek alanları taşır', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({ rows: [{ device_token: 'tok-1' }] });
        mockSend.mockResolvedValue({ failed: [] });

        await notifications.sendPushToUser(7, { ...OPTS, extra: { room_id: 42 } });
        await tickBekle();

        const note = mockSend.mock.calls[0][0];
        expect(note.alert).toEqual({ title: 'Oda daveti', body: 'Katıl!' });
        expect(note.payload).toEqual({ deep_link: 'menulo://room/ABC123', room_id: 42 });
    });

    // Ölü token'lar temizlenmezse her bildirimde tekrar denenir ve APNs
    // nezdinde gönderim itibarı düşer.
    test.each(['BadDeviceToken', 'Unregistered'])(
        '%s hatasında token DB\'den silinir',
        async (reason) => {
            const notifications = yukle();
            mockQuery
                .mockResolvedValueOnce({ rows: [{ device_token: 'olu-token' }] })
                .mockResolvedValueOnce({});
            mockSend.mockResolvedValue({ failed: [{ response: { reason } }] });

            await notifications.sendPushToUser(7, OPTS);
            await tickBekle();

            expect(mockQuery).toHaveBeenCalledWith(
                expect.stringContaining('DELETE FROM push_token'),
                ['olu-token']
            );
        }
    );

    test('başka bir hata sebebinde token silinmez', async () => {
        const notifications = yukle();
        mockQuery.mockResolvedValueOnce({ rows: [{ device_token: 'tok-1' }] });
        mockSend.mockResolvedValue({ failed: [{ response: { reason: 'TooManyRequests' } }] });

        await notifications.sendPushToUser(7, OPTS);
        await tickBekle();

        const silmeCagrisi = mockQuery.mock.calls.find(
            ([sql]) => typeof sql === 'string' && sql.includes('DELETE')
        );
        expect(silmeCagrisi).toBeUndefined();
    });

    // Push yan etki: çağıran akışı (odaya katılma vb.) asla bozmamalı.
    test('DB patlarsa throw etmez', async () => {
        const notifications = yukle();
        mockQuery.mockRejectedValueOnce(new Error('bağlantı koptu'));

        await expect(notifications.sendPushToUser(7, OPTS)).resolves.toBeUndefined();
    });

    test('temizlik sorgusu patlarsa da throw etmez', async () => {
        const notifications = yukle();
        mockQuery
            .mockResolvedValueOnce({ rows: [{ device_token: 'olu-token' }] })
            .mockRejectedValueOnce(new Error('silme başarısız'));
        mockSend.mockResolvedValue({
            failed: [{ response: { reason: 'BadDeviceToken' } }],
        });

        await expect(notifications.sendPushToUser(7, OPTS)).resolves.toBeUndefined();
        await tickBekle();
    });
});

// ─── Deep link üreticiler ───────────────────────────────────────────────────
//
// iOS tarafındaki CFBundleURLSchemes ("menulo") ile eşleşmek zorunda.
// Şema değişirse bildirime tıklama uygulamayı hiç açmaz — sessiz kırılma.

describe('deep link üreticiler', () => {
    test('oda linki menulo:// şemasını kullanır', () => {
        const notifications = yukle();
        expect(notifications.generateRoomDeepLink('ABC123')).toBe('menulo://room/ABC123');
    });

    test('restoran linki menulo:// şemasını kullanır', () => {
        const notifications = yukle();
        expect(notifications.generateRestaurantDeepLink(42)).toBe('menulo://restaurant/42');
    });
});
