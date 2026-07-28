// Jest yapılandırması.
//
// collectCoverageFrom olmadan Jest yalnızca testlerin require ettiği dosyaları
// sayar — test edilmemiş controller'lar yüzdeye hiç girmez ve coverage olduğundan
// yüksek görünür. Aşağıdaki liste tüm kaynak dosyaları ölçüme zorlar.
//
// routes/ hariç: dosyalar yalnızca router.get(path, middleware, controller)
// bildirimlerinden oluşuyor, unit test edilecek mantık içermiyor.
//
// NOT: coverageThreshold'a dosya bazlı anahtar (örn. './controllers/x.js')
// eklenirse Jest o dosyayı "global" grubundan ÇIKARIR ve global yüzde beklenmedik
// şekilde düşer. Bu yüzden tek bir global eşik kullanılıyor.

module.exports = {
    testEnvironment: 'node',

    collectCoverageFrom: [
        'controllers/**/*.js',
        'middleware/**/*.js',
    ],

    // Cırcır dişlisi: mevcut seviyenin hemen altında durur, yani testsiz kod
    // eklendiğinde ya da mevcut testler silindiğinde CI kırılır.
    // Kapsam arttıkça bu değerler yukarı çekilmeli.
    coverageThreshold: {
        global: {
            statements: 72,
            branches:   69,
            functions:  72,
            lines:      73,
        },
    },

    coverageReporters: ['text', 'text-summary', 'lcov'],
};
