const client = require('prom-client');

const register = new client.Registry();

// Node.js'in kendi varsayılan metrikleri: hafıza, CPU, event loop lag, GC vb.
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
    name: 'http_request_duration_seconds',
    help: 'HTTP isteklerinin yanıt süresi (saniye)',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
    registers: [register],
});

const httpRequestTotal = new client.Counter({
    name: 'http_requests_total',
    help: 'Toplam HTTP istek sayısı',
    labelNames: ['method', 'route', 'status_code'],
    registers: [register],
});

module.exports = { register, httpRequestDuration, httpRequestTotal };
