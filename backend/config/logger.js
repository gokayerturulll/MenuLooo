const isProd = process.env.NODE_ENV === 'production';
const isTest = process.env.NODE_ENV === 'test';

let logger;

if (isTest && !process.env.LOG_LEVEL) {
    // Jest her test dosyasını izole bir module registry'de çalıştırır, yani her
    // suite kendi pino instance'ını kurar. Pino, stdout'a flush için process'e
    // bir exit listener ekler — 10 suite bunu birikince MaxListenersExceeded
    // uyarısı çıkar. Test'te loglamanın kendisi zaten istenmediği için (eskiden
    // console.error/warn testlerde mock'lanıp susturuluyordu) hiç pino instance'ı
    // kurmuyoruz; LOG_LEVEL elle set edilirse (örn. tek bir testi debug ederken)
    // aşağıdaki gerçek pino dalına düşer.
    const noop = () => {};
    logger = { info: noop, warn: noop, error: noop, fatal: noop, debug: noop, trace: noop, child: () => logger };
} else {
    const pino = require('pino');

    // pino-pretty devDependency — Docker imajı `npm ci --omit=dev` ile kurulduğu
    // için container'da yok. NODE_ENV'e değil, paketin gerçekten var olmasına
    // bakıyoruz: host'ta (npm install ile) varsa renkli çıktı, yoksa (container,
    // prod) düz JSON'a otomatik düşer — hiçbir ortamda çökmez.
    let prettyAvailable = false;
    if (!isProd) {
        try {
            require.resolve('pino-pretty');
            prettyAvailable = true;
        } catch {
            prettyAvailable = false;
        }
    }

    logger = pino({
        level: process.env.LOG_LEVEL || 'info',
        transport: prettyAvailable
            ? {
                target: 'pino-pretty',
                options: { colorize: true, translateTime: 'HH:MM:ss', ignore: 'pid,hostname' },
            }
            : undefined,
    });
}

module.exports = logger;
