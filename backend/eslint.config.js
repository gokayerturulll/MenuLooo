// ESLint flat config (ESLint 9+).
//
// Amaç stil dayatmak değil, CI'da BUG yakalamak:
//   • no-undef        → yazım hatası olan değişken/fonksiyon (runtime'da ReferenceError)
//   • no-unused-vars  → yarım kalmış refactor, kullanılmayan import
//   • require-atomic-updates → async akışta race condition
//   • no-fallthrough  → switch içinde unutulan break
//
// Biçim kuralları (girinti, tırnak, noktalı virgül) kasıtlı olarak KAPALI —
// mevcut kod tabanıyla kavga etmesin diye.

const js = require('@eslint/js');
const globals = require('globals');

module.exports = [
    {
        ignores: ['node_modules/**', 'coverage/**', 'uploads/**'],
    },

    js.configs.recommended,

    {
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: 'commonjs',
            globals: globals.node,
        },
        rules: {
            // Kullanılmayan değişkenler hata — ama "_" ile başlayanlar kasıtlı sayılır
            // (örn. exports.getGreenMenu = async (_req, res) => ...).
            'no-unused-vars': ['error', {
                argsIgnorePattern:   '^_',
                varsIgnorePattern:   '^_',
                caughtErrorsIgnorePattern: '^_',
            }],

            // console.error/log backend'de kasıtlı olarak kullanılıyor.
            'no-console': 'off',

            // Bug'a dönüşen tipik hatalar
            'eqeqeq':                  ['error', 'smart'],
            'no-var':                  'error',
            'prefer-const':            'error',
            'require-atomic-updates':  'error',
            'no-await-in-loop':        'off', // uniquePin() bilinçli olarak kullanıyor
            'no-throw-literal':        'error',
            // Kapalı: prom-client'ın `new Gauge({ collect() {...} })` deseni
            // kendi kendine register olur — yan etki için new kullanmak burada doğru.
            'no-new':                  'off',
            'no-promise-executor-return': 'error',
            'no-unsafe-optional-chaining': 'error',
        },
    },

    {
        // Test dosyaları Jest global'lerini kullanır
        files: ['tests/**/*.js'],
        languageOptions: {
            globals: { ...globals.node, ...globals.jest },
        },
    },
];
