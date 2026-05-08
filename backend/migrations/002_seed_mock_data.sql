-- Migration: 002_seed_mock_data
-- Description: Massive seed for MenuLo RAG stress testing
--   • 50 restaurants (Anadolu + Avrupa Yakası, çeşitli mutfak konseptleri)
--   • 150 categories (3 per menu)
--   • 450 menu items (3 per category, ~9 per restaurant)
--   • Embedding placeholder: array_fill(0, ARRAY[3072])::vector
--     (seed_embeddings.js sonradan gerçek 3072d vektörlerle DROP+ADD eder)

-- 1. Clean existing data
TRUNCATE TABLE "restaurant" RESTART IDENTITY CASCADE;
TRUNCATE TABLE "user" RESTART IDENTITY CASCADE;

-- 2. Insert Users (1 Admin, 3 Owners, 5 Customers)
INSERT INTO "user" (role, username, email, phone_number, password_hash, location) VALUES
('Admin',    'admin_user',    'admin@menulo.com',         '+905550000001', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.02, 40.99), 4326)),
('Owner',    'owner_ahmet',   'ahmet@restaurant.com',     '+905550000002', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.03, 40.98), 4326)),
('Owner',    'owner_ayse',    'ayse@restaurant.com',      '+905550000003', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.10, 40.97), 4326)),
('Owner',    'owner_mehmet',  'mehmet@restaurant.com',    '+905550000004', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.05, 41.00), 4326)),
('Customer', 'cust_ali',      'ali@gmail.com',            '+905550000005', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.025, 40.985), 4326)),
('Customer', 'cust_zeynep',   'zeynep@gmail.com',         '+905550000006', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.09, 40.96), 4326)),
('Customer', 'cust_can',      'can@gmail.com',            '+905550000007', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.04, 40.99), 4326)),
('Customer', 'cust_elif',     'elif@gmail.com',           '+905550000008', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.11, 40.975), 4326)),
('Customer', 'cust_burak',    'burak@gmail.com',          '+905550000009', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.01, 41.01), 4326));

-- 3. Insert Restaurants (50 — Anadolu + Avrupa Yakası, çeşitli konseptler)
INSERT INTO restaurant (owner_id, business_name, address, location_point, work_hours) VALUES
-- ── Original 20 (Anadolu Yakası) ──
(2, 'Moda Burger',           'Caferağa Mah. Moda Cad. No: 12, Kadıköy',                       ST_SetSRID(ST_MakePoint(29.0251, 40.9852), 4326), '{"open": "10:00", "close": "23:00"}'),
(3, 'Ataşehir Kebap',         'Kayışdağı Mah. Uslu Sok. No: 5, Ataşehir',                      ST_SetSRID(ST_MakePoint(29.1411, 40.9785), 4326), '{"open": "11:00", "close": "22:00"}'),
(4, 'Bostancı Balıkçısı',     'Bostancı Mah. Bağdat Cad. No: 200, Kadıköy',                    ST_SetSRID(ST_MakePoint(29.0945, 40.9531), 4326), '{"open": "12:00", "close": "00:00"}'),
(2, 'Maltepe Pidecisi',       'Yalı Mah. Turgut Özal Bulvarı No: 10, Maltepe',                 ST_SetSRID(ST_MakePoint(29.1356, 40.9234), 4326), '{"open": "10:00", "close": "22:00"}'),
(3, 'Üsküdar Çaycısı',        'Mimar Sinan Mah. Hakimiyet-i Milliye Cad., Üsküdar',            ST_SetSRID(ST_MakePoint(29.0152, 41.0267), 4326), '{"open": "08:00", "close": "23:00"}'),
(4, 'Kadıköy Midye',          'Osmanağa Mah. Söğütlüçeşme Cad., Kadıköy',                      ST_SetSRID(ST_MakePoint(29.0305, 40.9912), 4326), '{"open": "12:00", "close": "02:00"}'),
(2, 'Barbaros Kahve',         'Barbaros Mah. Ihlamur Bulvarı, Ataşehir',                       ST_SetSRID(ST_MakePoint(29.1023, 40.9956), 4326), '{"open": "07:00", "close": "20:00"}'),
(3, 'Suadiye Steakhouse',     'Suadiye Mah. Bağdat Cad., Kadıköy',                             ST_SetSRID(ST_MakePoint(29.0812, 40.9623), 4326), '{"open": "12:00", "close": "23:30"}'),
(4, 'İçerenköy Döner',        'İçerenköy Mah. Prof. Dr. Necmettin Erbakan Cad., Ataşehir',     ST_SetSRID(ST_MakePoint(29.1124, 40.9756), 4326), '{"open": "11:00", "close": "21:00"}'),
(2, 'Altıntepe Pastanesi',    'Altıntepe Mah. Minibüs Yolu, Maltepe',                          ST_SetSRID(ST_MakePoint(29.1034, 40.9451), 4326), '{"open": "07:00", "close": "21:00"}'),
(3, 'Kalamış Brasserie',      'Fenerbahçe Mah. Kalamış Fener Cad., Kadıköy',                   ST_SetSRID(ST_MakePoint(29.0398, 40.9745), 4326), '{"open": "09:00", "close": "00:00"}'),
(4, 'Kozyatağı Pizzeria',     'Kozyatağı Mah. Bayar Cad., Kadıköy',                            ST_SetSRID(ST_MakePoint(29.0965, 40.9732), 4326), '{"open": "11:30", "close": "22:30"}'),
(2, 'Kuzguncuk Fırını',       'Kuzguncuk Mah. İcadiye Cad., Üsküdar',                          ST_SetSRID(ST_MakePoint(29.0315, 41.0367), 4326), '{"open": "06:00", "close": "19:00"}'),
(3, 'Acıbadem Tatlıcısı',     'Acıbadem Mah. Acıbadem Cad., Üsküdar',                          ST_SetSRID(ST_MakePoint(29.0456, 41.0023), 4326), '{"open": "08:00", "close": "22:00"}'),
(4, 'Işıklar Mantı',          'Küçükbakkalköy Mah. Işıklar Cad., Ataşehir',                    ST_SetSRID(ST_MakePoint(29.1154, 40.9821), 4326), '{"open": "10:00", "close": "21:30"}'),
(2, 'Hasanpaşa Köftecisi',    'Hasanpaşa Mah. Kurbağalıdere Cad., Kadıköy',                    ST_SetSRID(ST_MakePoint(29.0387, 40.9934), 4326), '{"open": "11:00", "close": "22:00"}'),
(3, 'Çengelköy Çikolatacısı', 'Çengelköy Mah. Çengelköy Cad., Üsküdar',                        ST_SetSRID(ST_MakePoint(29.0521, 41.0501), 4326), '{"open": "09:00", "close": "23:00"}'),
(4, 'İdealtepe Izgara',       'İdealtepe Mah. Rıfkı Tongsir Cad., Maltepe',                    ST_SetSRID(ST_MakePoint(29.1235, 40.9387), 4326), '{"open": "12:00", "close": "23:00"}'),
(2, 'Göztepe Makarna',        'Göztepe Mah. Tütüncü Mehmet Efendi Cad., Kadıköy',              ST_SetSRID(ST_MakePoint(29.0645, 40.9781), 4326), '{"open": "11:30", "close": "22:00"}'),
(3, 'Ataşehir Sushico',       'Atatürk Mah. Ataşehir Bulvarı, Ataşehir',                       ST_SetSRID(ST_MakePoint(29.1213, 40.9912), 4326), '{"open": "12:00", "close": "23:00"}'),
-- ── Anadolu Yakası — Yeni konseptler ──
(4, 'Caddebostan Vegan Bistro',   'Caddebostan Mah. Bağdat Cad. No: 312, Kadıköy',             ST_SetSRID(ST_MakePoint(29.0635, 40.9612), 4326), '{"open": "10:00", "close": "22:00"}'),
(2, 'Suadiye Sushi Master',       'Suadiye Mah. Plaj Yolu Sok., Kadıköy',                       ST_SetSRID(ST_MakePoint(29.0789, 40.9610), 4326), '{"open": "12:00", "close": "23:30"}'),
(3, 'Moda Kahvaltı Evi',          'Caferağa Mah. Mühürdar Cad., Kadıköy',                       ST_SetSRID(ST_MakePoint(29.0265, 40.9870), 4326), '{"open": "07:30", "close": "16:00"}'),
(4, 'Bağdat Kokoreççisi',         'Şaşkınbakkal Mah. Bağdat Cad. No: 412, Kadıköy',             ST_SetSRID(ST_MakePoint(29.0723, 40.9645), 4326), '{"open": "16:00", "close": "03:00"}'),
(2, 'Kadıköy Tacos',              'Caferağa Mah. Sakız Sok., Kadıköy',                          ST_SetSRID(ST_MakePoint(29.0289, 40.9886), 4326), '{"open": "11:00", "close": "00:00"}'),
(3, 'Üsküdar Karadeniz Mutfağı',  'Salacak Mah. Selman-i Pak Cad., Üsküdar',                    ST_SetSRID(ST_MakePoint(29.0098, 41.0287), 4326), '{"open": "11:00", "close": "22:00"}'),
(4, 'Ataşehir Wokery',            'Atatürk Mah. Vedat Günyol Cad., Ataşehir',                   ST_SetSRID(ST_MakePoint(29.1289, 40.9889), 4326), '{"open": "12:00", "close": "23:00"}'),
(2, 'Bostancı Kahve Atölyesi',    'Bostancı Mah. Çatalçeşme Sok., Kadıköy',                     ST_SetSRID(ST_MakePoint(29.0911, 40.9558), 4326), '{"open": "08:00", "close": "21:00"}'),
(3, 'Maltepe Tükürük Köftecisi',  'Cevizli Mah. E-5 Yan Yolu, Maltepe',                         ST_SetSRID(ST_MakePoint(29.1378, 40.9268), 4326), '{"open": "10:00", "close": "23:00"}'),
(4, 'Erenköy Vegan House',        'Erenköy Mah. Ethemefendi Cad., Kadıköy',                     ST_SetSRID(ST_MakePoint(29.0712, 40.9712), 4326), '{"open": "10:00", "close": "22:00"}'),
(2, 'Caddebostan Salata Bar',     'Caddebostan Mah. Bağdat Cad. No: 280, Kadıköy',             ST_SetSRID(ST_MakePoint(29.0598, 40.9628), 4326), '{"open": "09:00", "close": "21:00"}'),
(3, 'Kozyatağı Antep Lezzetleri', 'Kozyatağı Mah. Sahrayıcedid Cad., Kadıköy',                  ST_SetSRID(ST_MakePoint(29.0998, 40.9747), 4326), '{"open": "11:00", "close": "23:00"}'),
(4, 'Suadiye Brunch Cafe',        'Suadiye Mah. Bağdat Cad. No: 415, Kadıköy',                  ST_SetSRID(ST_MakePoint(29.0851, 40.9608), 4326), '{"open": "08:00", "close": "17:00"}'),
-- ── Avrupa Yakası ──
(2, 'Beşiktaş Köftecisi',         'Sinanpaşa Mah. Köyiçi Cad., Beşiktaş',                       ST_SetSRID(ST_MakePoint(29.0067, 41.0429), 4326), '{"open": "11:00", "close": "23:00"}'),
(3, 'Taksim Pizzeria Roma',       'Cumhuriyet Mah. İstiklal Cad. No: 145, Beyoğlu',             ST_SetSRID(ST_MakePoint(28.9867, 41.0367), 4326), '{"open": "11:30", "close": "00:30"}'),
(4, 'Bakırköy Kahvaltı Evi',      'Cevizlik Mah. Ebuzziya Cad., Bakırköy',                      ST_SetSRID(ST_MakePoint(28.8732, 40.9789), 4326), '{"open": "07:00", "close": "16:00"}'),
(2, 'Küçükçekmece Et Mangal',     'Cennet Mah. Eski Halkalı Cad., Küçükçekmece',                ST_SetSRID(ST_MakePoint(28.7821, 41.0001), 4326), '{"open": "12:00", "close": "23:30"}'),
(3, 'Florya Sahil Balık',         'Florya Cad. No: 88, Bakırköy',                                ST_SetSRID(ST_MakePoint(28.7912, 40.9712), 4326), '{"open": "12:00", "close": "00:00"}'),
(4, 'Beyoğlu Vegan Lab',          'Asmalı Mescit Mah. Sofyalı Sok., Beyoğlu',                   ST_SetSRID(ST_MakePoint(28.9745, 41.0312), 4326), '{"open": "11:00", "close": "23:00"}'),
(2, 'Cihangir Specialty Coffee',  'Cihangir Mah. Akarsu Cad., Beyoğlu',                         ST_SetSRID(ST_MakePoint(28.9823, 41.0312), 4326), '{"open": "08:00", "close": "21:00"}'),
(3, 'Levent Sushi Bar',           'Levent Mah. Büyükdere Cad. No: 201, Şişli',                  ST_SetSRID(ST_MakePoint(29.0145, 41.0823), 4326), '{"open": "12:00", "close": "23:30"}'),
(4, 'Beşiktaş Mexican Cantina',   'Sinanpaşa Mah. Çırağan Cad., Beşiktaş',                      ST_SetSRID(ST_MakePoint(29.0089, 41.0445), 4326), '{"open": "12:00", "close": "01:00"}'),
(2, 'Etiler Doğu Mutfağı',        'Etiler Mah. Nispetiye Cad., Beşiktaş',                       ST_SetSRID(ST_MakePoint(29.0312, 41.0801), 4326), '{"open": "12:00", "close": "23:30"}'),
(3, 'Bebek Brunch & More',        'Bebek Mah. Cevdetpaşa Cad., Beşiktaş',                       ST_SetSRID(ST_MakePoint(29.0445, 41.0789), 4326), '{"open": "08:00", "close": "18:00"}'),
(4, 'Karaköy Kokoreçhanesi',      'Kemankeş Mah. Mumhane Cad., Beyoğlu',                        ST_SetSRID(ST_MakePoint(28.9745, 41.0245), 4326), '{"open": "17:00", "close": "04:00"}'),
(2, 'Galata Kahve Sanatı',        'Bereketzade Mah. Galata Kulesi Sok., Beyoğlu',               ST_SetSRID(ST_MakePoint(28.9745, 41.0256), 4326), '{"open": "08:00", "close": "22:00"}'),
(3, 'Şişli Kebap Sarayı',         'Halaskargazi Mah. Halaskargazi Cad., Şişli',                 ST_SetSRID(ST_MakePoint(28.9912, 41.0612), 4326), '{"open": "11:30", "close": "23:30"}'),
(4, 'Beyoğlu Sokak Tatlıcısı',    'Hüseyinağa Mah. İstiklal Cad. No: 89, Beyoğlu',              ST_SetSRID(ST_MakePoint(28.9789, 41.0345), 4326), '{"open": "10:00", "close": "00:00"}'),
(2, 'Yeşilköy Vegan Garden',      'Yeşilköy Mah. İstasyon Cad., Bakırköy',                      ST_SetSRID(ST_MakePoint(28.8267, 40.9678), 4326), '{"open": "10:00", "close": "22:00"}'),
(3, 'Bakırköy Anatolian Grill',   'Yeşilyurt Mah. Şenlikköy Cad., Bakırköy',                    ST_SetSRID(ST_MakePoint(28.8378, 40.9712), 4326), '{"open": "12:00", "close": "23:00"}');

-- 4. Insert Menus (1 per restaurant, total 50)
INSERT INTO menu (restaurant_id) VALUES
(1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),
(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),
(31),(32),(33),(34),(35),(36),(37),(38),(39),(40),
(41),(42),(43),(44),(45),(46),(47),(48),(49),(50);

-- 5. Insert Categories (3 per menu — total 150)
INSERT INTO category (menu_id, name) VALUES
-- 1. Moda Burger
(1, 'Burgerler'),(1, 'Yan Lezzetler'),(1, 'İçecekler'),
-- 2. Ataşehir Kebap
(2, 'Kebaplar'),(2, 'Mezeler'),(2, 'Tatlılar'),
-- 3. Bostancı Balıkçısı
(3, 'Deniz Ürünleri'),(3, 'Mezeler'),(3, 'Salatalar'),
-- 4. Maltepe Pidecisi
(4, 'Pideler'),(4, 'Çorbalar'),(4, 'Salatalar'),
-- 5. Üsküdar Çaycısı
(5, 'Çaylar'),(5, 'Atıştırmalıklar'),(5, 'Sıcak İçecekler'),
-- 6. Kadıköy Midye
(6, 'Midyeler'),(6, 'Sokak Lezzetleri'),(6, 'İçecekler'),
-- 7. Barbaros Kahve
(7, 'Kahveler'),(7, 'Tatlılar'),(7, 'Sandviçler'),
-- 8. Suadiye Steakhouse
(8, 'Izgara Etler'),(8, 'Şaraplar'),(8, 'Başlangıçlar'),
-- 9. İçerenköy Döner
(9, 'Dönerler'),(9, 'Pilavlar'),(9, 'İçecekler'),
-- 10. Altıntepe Pastanesi
(10, 'Pastalar'),(10, 'Sıcak İçecekler'),(10, 'Kurabiyeler'),
-- 11. Kalamış Brasserie
(11, 'Ana Yemekler'),(11, 'Kokteyller'),(11, 'Tatlılar'),
-- 12. Kozyatağı Pizzeria
(12, 'Pizzalar'),(12, 'Başlangıçlar'),(12, 'Tatlılar'),
-- 13. Kuzguncuk Fırını
(13, 'Unlu Mamuller'),(13, 'Çay & Kahve'),(13, 'Tatlılar'),
-- 14. Acıbadem Tatlıcısı
(14, 'Sütlü Tatlılar'),(14, 'Şerbetli Tatlılar'),(14, 'İçecekler'),
-- 15. Işıklar Mantı
(15, 'Mantılar'),(15, 'Çorbalar'),(15, 'Mezeler'),
-- 16. Hasanpaşa Köftecisi
(16, 'Köfteler'),(16, 'Piyaz ve Salata'),(16, 'İçecekler'),
-- 17. Çengelköy Çikolatacısı
(17, 'Özel Çikolatalar'),(17, 'Kahveler'),(17, 'Pastalar'),
-- 18. İdealtepe Izgara
(18, 'Izgara Çeşitleri'),(18, 'Mezeler'),(18, 'İçecekler'),
-- 19. Göztepe Makarna
(19, 'Makarnalar'),(19, 'İtalyan Tatlıları'),(19, 'Şaraplar'),
-- 20. Ataşehir Sushico
(20, 'Sushi Rolls'),(20, 'Noodle Çeşitleri'),(20, 'Asya İçecekleri'),
-- 21. Caddebostan Vegan Bistro
(21, 'Vegan Ana Yemekler'),(21, 'Vegan Burgerler'),(21, 'Vegan Tatlılar'),
-- 22. Suadiye Sushi Master
(22, 'Premium Sushi'),(22, 'Sashimi'),(22, 'Maki Çeşitleri'),
-- 23. Moda Kahvaltı Evi
(23, 'Serpme Kahvaltı'),(23, 'Yumurtalı Tabaklar'),(23, 'Sıcak İçecekler'),
-- 24. Bağdat Kokoreççisi
(24, 'Kokoreç Çeşitleri'),(24, 'Yan Lezzetler'),(24, 'İçecekler'),
-- 25. Kadıköy Tacos
(25, 'Tacos'),(25, 'Burritos'),(25, 'Meksika İçecekleri'),
-- 26. Üsküdar Karadeniz Mutfağı
(26, 'Karadeniz Yemekleri'),(26, 'Hamsi Çeşitleri'),(26, 'Tatlılar'),
-- 27. Ataşehir Wokery
(27, 'Wok Yemekleri'),(27, 'Asya Çorbaları'),(27, 'Dim Sum'),
-- 28. Bostancı Kahve Atölyesi
(28, 'Specialty Kahveler'),(28, 'Tatlılar'),(28, 'Brunch'),
-- 29. Maltepe Tükürük Köftecisi
(29, 'Tükürük Köfteleri'),(29, 'Yan Lezzetler'),(29, 'İçecekler'),
-- 30. Erenköy Vegan House
(30, 'Vegan Ana Yemekler'),(30, 'Vegan Salatalar'),(30, 'Vegan Tatlılar'),
-- 31. Caddebostan Salata Bar
(31, 'Sağlıklı Salatalar'),(31, 'Soğuk Çorbalar'),(31, 'Smoothie'),
-- 32. Kozyatağı Antep Lezzetleri
(32, 'Antep Kebapları'),(32, 'Antep Tatlıları'),(32, 'Antep Mezeleri'),
-- 33. Suadiye Brunch Cafe
(33, 'Brunch Tabakları'),(33, 'Pancake & Waffle'),(33, 'Taze Sıkma Sular'),
-- 34. Beşiktaş Köftecisi
(34, 'Köfteler'),(34, 'Yan Yemekler'),(34, 'İçecekler'),
-- 35. Taksim Pizzeria Roma
(35, 'Klasik Pizzalar'),(35, 'Gourmet Pizzalar'),(35, 'Antipasti'),
-- 36. Bakırköy Kahvaltı Evi
(36, 'Köy Kahvaltısı'),(36, 'Sıcaklar'),(36, 'Çay & Kahve'),
-- 37. Küçükçekmece Et Mangal
(37, 'Et Çeşitleri'),(37, 'Tavuk Izgara'),(37, 'Yan Lezzetler'),
-- 38. Florya Sahil Balık
(38, 'Mevsim Balıkları'),(38, 'Mezeler'),(38, 'Şaraplar'),
-- 39. Beyoğlu Vegan Lab
(39, 'Vegan Bowls'),(39, 'Plant-Based Burgerler'),(39, 'Raw Tatlılar'),
-- 40. Cihangir Specialty Coffee
(40, 'Filtre Kahveler'),(40, 'Espresso Bazlı'),(40, 'Tatlılar'),
-- 41. Levent Sushi Bar
(41, 'Premium Sushi'),(41, 'Donburi'),(41, 'Yakitori'),
-- 42. Beşiktaş Mexican Cantina
(42, 'Tacos & Burritos'),(42, 'Quesadillas'),(42, 'Margaritalar'),
-- 43. Etiler Doğu Mutfağı
(43, 'Çin Yemekleri'),(43, 'Tayland Lezzetleri'),(43, 'Asya İçecekleri'),
-- 44. Bebek Brunch & More
(44, 'Brunch Klasikleri'),(44, 'Yumurtalı Lezzetler'),(44, 'Smoothie & Juice'),
-- 45. Karaköy Kokoreçhanesi
(45, 'Kokoreç Çeşitleri'),(45, 'Sokak Atıştırmaları'),(45, 'İçecekler'),
-- 46. Galata Kahve Sanatı
(46, 'Türk Kahvesi Çeşitleri'),(46, 'Espresso Bazlı'),(46, 'Tatlılar'),
-- 47. Şişli Kebap Sarayı
(47, 'Şiş Kebaplar'),(47, 'Mezeler'),(47, 'Tatlılar'),
-- 48. Beyoğlu Sokak Tatlıcısı
(48, 'Sokak Tatlıları'),(48, 'Dondurmalar'),(48, 'Sıcak İçecekler'),
-- 49. Yeşilköy Vegan Garden
(49, 'Vegan Bowls'),(49, 'Vegan Pizzalar'),(49, 'Vegan Tatlılar'),
-- 50. Bakırköy Anatolian Grill
(50, 'Anadolu Izgaraları'),(50, 'Yöresel Mezeler'),(50, 'Şerbetli Tatlılar');

-- 6. Insert Menu Items (3 per category — total 450)
-- Pattern: ürünün description'ı RAG için zengin tutuldu; dietary_tags gerçekçi.
INSERT INTO menu_item (category_id, name, price, description, dietary_tags, embedding) VALUES
-- ── Cat 1-3 (Moda Burger) ──
(1, 'Klasik Burger',         180.00, 'Izgara dana köfte, taze marul, dilim domates, kornişon turşu ve özel sosumuzla glutenli ekmek arasında.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(1, 'Cheeseburger',          210.00, 'Çift dana köfte ve eritilmiş cheddar peyniri, taze marul, soğan halkaları ve karamelize sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(1, 'BBQ Bacon Burger',      240.00, 'Smokey BBQ soslu dana köfte, çıtır pastırma, çedar peyniri ve karamelize soğan.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(2, 'Patates Kızartması',    60.00,  'Çıtır altın rengi patates kızartması, deniz tuzu ile.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(2, 'Soğan Halkası',         70.00,  'Bira hamuruna bulanmış çıtır soğan halkaları, yanında ranch sos.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(2, 'Tavuk Kanat (4 Adet)',  130.00, 'Acılı buffalo soslu tavuk kanat, blue cheese sos eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(3, 'Kutu Kola',             40.00,  'Buz gibi 330ml kutu kola.', '{}', array_fill(0, ARRAY[3072])::vector),
(3, 'Ev Yapımı Limonata',    55.00,  'Taze sıkılmış limonun naneyle buluştuğu ferahlatıcı limonata.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(3, 'Vanilyalı Milkshake',   80.00,  'Madagaskar vanilyalı, kremalı milkshake, çikolata sos eşliğinde.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 4-6 (Ataşehir Kebap) ──
(4, 'Adana Kebap',           280.00, 'Zırh ile dövülmüş elle hazırlanan kıymalı acılı Adana kebabı, közlenmiş domates ve biber ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(4, 'Urfa Kebap',            280.00, 'Acısız Urfa usulü kıyma kebabı, lavaş ekmek ve sumaklı soğan eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(4, 'Beyti Sarma',           320.00, 'Sıcak lavaşa sarılmış beyti, yoğurt ve domates sosuyla.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(5, 'Haydari',               70.00,  'Süzme yoğurt, taze nane ve sarımsakla hazırlanmış meze.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(5, 'Acılı Ezme',            65.00,  'Domates, biber ve cevizle hazırlanmış nar ekşili acılı ezme.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(5, 'Patlıcan Salata',       75.00,  'Közlenmiş patlıcan, sarımsak ve zeytinyağıyla hazırlanmış meze.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(6, 'Künefe',                120.00, 'Kadayıf ve özel hatay peyniri ile hazırlanan, fıstık serpilmiş sıcak künefe.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(6, 'Sütlaç',                80.00,  'Fırında pişirilmiş klasik tarçınlı sütlaç.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(6, 'Fıstıklı Baklava',      140.00, 'Yufkalar arasına Antep fıstığı yerleştirilmiş şerbetli baklava.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 7-9 (Bostancı Balıkçısı) ──
(7, 'Izgara Levrek',         350.00, 'Akdeniz tipi taze deniz levreği, ızgarada limon ve roka eşliğinde.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(7, 'Kalamar Tava',          220.00, 'Çıtır kızarmış kalamar halkaları, ev yapımı tarator sos eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(7, 'Çupra Buğulama',        330.00, 'Sebzeli ve domatesli buğulama çupra, taze fesleğen ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(8, 'Karides Güveç',         260.00, 'Domatesli, kaşarlı, fırında karides güvecinde, yanında kızarmış ekmek.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(8, 'Lakerda',               140.00, 'Ev yapımı tuzlanmış torik balığı, soğan ve dereotu ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(8, 'Fava',                  70.00,  'Zeytinyağlı yumuşak fava, soğan ve dereotu ile.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(9, 'Roka Salata',           90.00,  'Taze roka, çekirdeksiz domates, cevizli ve nar ekşili sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(9, 'Karışık Yeşil Salata',  85.00,  'Mevsim yeşillikleri, salatalık, domates ve sumaklı sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(9, 'Ahtapot Salata',        180.00, 'Haşlanmış ahtapot, soğan, kapari ve zeytinyağı.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 10-12 (Maltepe Pidecisi) ──
(10, 'Kıymalı Pide',         160.00, 'Özel baharatlı kıyma, soğan ve maydanozla hazırlanan elde açma pide.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(10, 'Kaşarlı Pide',         150.00, 'Bol kaşar peyniri ve yumurta sarısı eşliğinde fırın pide.', '{"Vejetaryen", "Helal"}', array_fill(0, ARRAY[3072])::vector),
(10, 'Karışık Pide',         185.00, 'Kıyma, kaşar, yumurta ve sucuklu karışık pide.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(11, 'Mercimek Çorbası',     60.00,  'Klasik süzme kırmızı mercimek çorbası, limon ve nane sosu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(11, 'İşkembe Çorbası',      75.00,  'Klasik beyaz işkembe çorbası, sarımsak ve sirke ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(11, 'Ezogelin Çorbası',     65.00,  'Bulgur, mercimek ve nane ile pişen klasik ezogelin.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(12, 'Çoban Salata',         80.00,  'Domates, salatalık, biber, soğan ve zeytinyağıyla hazırlanmış mevsim salatası.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(12, 'Gavurdağı Salata',     110.00, 'İnce kıyılmış domates, ceviz ve nar ekşili Gaziantep salatası.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(12, 'Kısır',                75.00,  'İnce bulgur, nar ekşisi ve baharatlarla hazırlanmış soğuk kısır.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 13-15 (Üsküdar Çaycısı) ──
(13, 'Demleme Çay',          20.00,  'İnce belli bardakta servis edilen demli Rize çayı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(13, 'Bitki Çayı',           35.00,  'Adaçayı, ıhlamur veya kış çayı seçenekleri ile.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(13, 'Tarçınlı Elma Çayı',   30.00,  'Sıcak su, taze elma dilimleri ve tarçın çubuğu ile demleme.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(14, 'Simit',                15.00,  'Susamlı sokak simidi.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(14, 'Kaşarlı Tost',         60.00,  'Tam buğday ekmeğinde eritilmiş kaşar peyniri.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(14, 'Açma',                 18.00,  'Tereyağlı puf açma, taze ve yumuşak.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(15, 'Salep',                75.00,  'Tarçınlı sıcak salep, kış akşamlarına özel.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(15, 'Türk Kahvesi',         50.00,  'Orta kavrulmuş geleneksel Türk kahvesi, lokum ile servis.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(15, 'Sıcak Çikolata',       65.00,  'Belçika çikolatasından hazırlanan kremalı sıcak çikolata.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 16-18 (Kadıköy Midye) ──
(16, 'Midye Dolma (10 Adet)', 100.00, 'Baharatlı pirinç dolgulu, limonla servis edilen midye dolma.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(16, 'Midye Tava (250g)',    180.00, 'Çıtır kızartılmış midye tava, ev yapımı tarator sos eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(16, 'Midyeli Pilav',        140.00, 'Yağda kavrulmuş soğan, midye ve baharatlı pilav.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(17, 'Kokoreç Yarım Ekmek',  140.00, 'Bol baharatlı, közde pişmiş kuzu kokoreç, yarım ekmek arasında.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(17, 'Tatlı Patates',        65.00,  'Karamelize edilmiş tatlı patates kızartması, deniz tuzu ile.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(17, 'Lavaş Sarması',        80.00,  'Sucuklu, kaşarlı sıcak lavaş sarması.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(18, 'Şalgam Suyu',          30.00,  'Acılı veya acısız taze şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(18, 'Ayran',                25.00,  'Köpüklü, açık ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(18, 'Limonata',             45.00,  'Taze sıkılmış buzlu limonata.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 19-21 (Barbaros Kahve) ──
(19, 'Filtre Kahve',         70.00,  'Taze kavrulmuş Arabica taneleriyle V60 demleme filtre kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(19, 'Latte',                85.00,  'Çift shot espresso ve buharla ısıtılmış süt.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(19, 'Cappuccino',           80.00,  'Espresso, buharlı süt ve kalın süt köpüğü.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(20, 'Cheesecake',           110.00, 'New York usulü klasik cheesecake, frambuaz sosu ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(20, 'Brownie',              105.00, 'Cevizli ıslak brownie, vanilyalı dondurma topu ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(20, 'Tiramisu',             115.00, 'Mascarpone peyniri ve espresso ile hazırlanmış İtalyan tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(21, 'Tavuklu Sandviç',      130.00, 'Izgara tavuk göğsü, lor peyniri, marul ve sürme sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(21, 'Avokadolu Tost',       125.00, 'Ekşi mayalı ekmek üzerinde ezilmiş avokado, kiraz domates ve çırpılmış yumurta.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(21, 'Klüp Sandviç',         145.00, 'Tavuk, dana füme, peynir ve domates ile üç katlı klüp sandviç.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 22-24 (Suadiye Steakhouse) ──
(22, 'Lokum Antrikot (300g)', 650.00, 'Yumuşacık dilimlenmiş Angus antrikot, közlenmiş sebze ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(22, 'Dallas Steak (450g)',  750.00, 'Kemikli dana pirzola, kemiğinde pişmiş etin lezzeti.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(22, 'Bonfile Mantar Sos',   620.00, 'Yumuşak dana bonfile, mantar kremalı özel sos eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(23, 'Kırmızı Şarap (Kadeh)', 250.00, 'Yerli üretici Cabernet Sauvignon kadeh.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(23, 'Beyaz Şarap (Kadeh)',  250.00, 'Yerli üretici Sauvignon Blanc kadeh.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(23, 'Şampanya (Kadeh)',     320.00, 'Premium fransız brut şampanya kadeh.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(24, 'Mantar Çorbası',       95.00,  'Kremalı mantar çorbası, taze mantar tane parçaları ile.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(24, 'Foie Gras',            290.00, 'Klasik fransız foie gras, fındıklı brioche ekmek üzerinde.', '{}', array_fill(0, ARRAY[3072])::vector),
(24, 'Carpaccio',            210.00, 'İnce kesilmiş çiğ dana bonfile, parmesan ve roka ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 25-27 (İçerenköy Döner) ──
(25, 'Porsiyon Döner',       240.00, 'Yaprak yaprak dilimlenmiş et döner, pilav ve közlenmiş biber ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(25, 'İskender (450g)',      290.00, 'Tereyağlı İskender kebap, domates sosu ve yoğurt ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(25, 'Tavuk Döner',          200.00, 'Yağsız tavuk döner, baharatlı pirinç pilavı ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(26, 'Sade Pilav',           50.00,  'Tereyağlı klasik pirinç pilavı.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(26, 'Bulgur Pilavı',        55.00,  'Domatesli ve isotlu bulgur pilavı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(26, 'Mercimekli Bulgur',    60.00,  'Yeşil mercimekli ve soğanlı bulgur pilavı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(27, 'Ayran',                25.00,  'Köpüklü ev usulü ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(27, 'Şalgam',               30.00,  'Acılı turp şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(27, 'Su',                   10.00,  'Pet şişe içme suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 28-30 (Altıntepe Pastanesi) ──
(28, 'Çilekli Pasta',        90.00,  'Taze çilek ve kremalı yaş pasta dilimi.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(28, 'Profiterol',           85.00,  'Çikolata sosuna boğulmuş profiterol topları.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(28, 'Frambuazlı Tart',      95.00,  'Vanilya kreması ve taze frambuazla hazırlanmış tart dilimi.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(29, 'Türk Kahvesi',         50.00,  'Lokum eşliğinde geleneksel Türk kahvesi.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(29, 'Sahlep',               75.00,  'Tarçınlı sıcak sahlep.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(29, 'Espresso',             45.00,  'Tek shot İtalyan espresso.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(30, 'Tereyağlı Kurabiye',   30.00,  'Erimiş tereyağı kokulu, ufalanan kurabiye.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(30, 'Kakaolu Kurabiye',     35.00,  'Kakaolu, çift sürpriz çikolata damlalı kurabiye.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(30, 'Tahinli Kurabiye',     32.00,  'Tahin ve pekmezle hazırlanmış vegan kurabiye.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 31-33 (Kalamış Brasserie) ──
(31, 'Izgara Somon',         420.00, 'Mevsim yeşillikleri ve limonlu sosla servis edilen Atlantik somon.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(31, 'Tavuk Şinitzel',       280.00, 'Çıtır galeta kaplamalı tavuk göğsü şinitzel, patates salatası ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(31, 'Risotto Funghi',       260.00, 'Mantarlı kremalı arborio pirinci risotto.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(32, 'Mojito',               220.00, 'Beyaz rom, taze nane, lime ve şekerle hazırlanmış kokteyl.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(32, 'Margarita',            240.00, 'Tequila, triple sec ve taze lime ile klasik margarita.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(32, 'Aperol Spritz',        230.00, 'Aperol, prosecco ve soda ile İtalyan aperitifi.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(33, 'Crème Brûlée',         140.00, 'Karamelize üst kabuklu vanilyalı krema tatlısı.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(33, 'Lava Kek',             125.00, 'Akan çikolatalı sıcak lava kek, vanilyalı dondurma ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(33, 'Panna Cotta',          110.00, 'Krema bazlı İtalyan tatlısı, orman meyveleri sosu ile.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 34-36 (Kozyatağı Pizzeria) ──
(34, 'Margherita',           210.00, 'İnce hamur, San Marzano domates sosu, taze mozzarella ve fesleğen.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(34, 'Pepperoni',            250.00, 'Acılı pepperoni dilimleri ve mozzarella peyniri ile İtalyan klasiği.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(34, 'Quattro Formaggi',     270.00, 'Mozzarella, gorgonzola, parmesan ve fontina ile dört peynir pizza.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(35, 'Sarımsaklı Ekmek',     70.00,  'Tereyağı ve sarımsakla fırınlanmış sıcak ekmek.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(35, 'Bruschetta',           90.00,  'Domatesli, fesleğenli ve sarımsaklı kızarmış ekmek.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(35, 'Sezar Salata',         140.00, 'Marul, parmesan, kruton ve klasik sezar sos ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(36, 'Tiramisu',             120.00, 'Mascarpone ve espresso ile geleneksel İtalyan tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(36, 'Cannoli',              105.00, 'Çıtır kabuk içinde ricotta peyniri ve çikolata damlaları.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(36, 'Affogato',             90.00,  'Espresso üzerine vanilyalı dondurma topu.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 37-39 (Kuzguncuk Fırını) ──
(37, 'Ekşi Mayalı Ekmek',    45.00,  'Artizan ekşi mayalı tam buğday ekmeği, çıtır kabuklu.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(37, 'Zeytinli Açma',        25.00,  'Yağlı zeytin parçacıklı puf açma.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(37, 'Pastırmalı Çörek',     55.00,  'Tereyağlı çörek arasında tütsülenmiş pastırma.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(38, 'Türk Çayı',            18.00,  'Demli klasik Türk çayı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(38, 'Filtre Kahve',         55.00,  'Taze demlenmiş filtre kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(38, 'Soğuk Limonata',       40.00,  'Buz parçacıklarıyla servis edilen ev limonatası.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(39, 'Cevizli Kurabiye',     30.00,  'Bol cevizli, ağızda dağılan kurabiye.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(39, 'Tahinli Çörek',        28.00,  'Taze fırından tahinli çörek.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(39, 'Vişneli Tart',         85.00,  'Ev yapımı vişne tartı, tereyağlı taban ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 40-42 (Acıbadem Tatlıcısı) ──
(40, 'Kazandibi',            75.00,  'Tabanı kızartılmış sütlü tatlı, tarçın ile.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(40, 'Tavukgöğsü',           75.00,  'Gerçek tavuk eti lifleriyle hazırlanan klasik sütlü tatlı.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(40, 'Keşkül',               65.00,  'Bademli klasik keşkül, üzerinde fıstık serpilmiş.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(41, 'Fıstıklı Baklava',     140.00, 'Antep fıstıklı, ince yufkalı geleneksel şerbetli baklava.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(41, 'Şöbiyet',              150.00, 'Üçgen şeklinde, kaymak dolgulu şerbetli tatlı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(41, 'Kalburabasti',         110.00, 'Cevizli şerbetli, hamuru kalbur şeklinde sıkılı tatlı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(42, 'Türk Kahvesi',         50.00,  'Geleneksel orta kavrulmuş Türk kahvesi.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(42, 'Salep',                70.00,  'Tarçın aromalı sıcak salep.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(42, 'Şalgam',               30.00,  'Acılı şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 43-45 (Işıklar Mantı) ──
(43, 'Klasik Mantı',         180.00, 'Sarımsaklı yoğurt ve naneli tereyağlı sosla servis edilen Kayseri mantısı.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(43, 'Çıtır Mantı',          190.00, 'Yoğun çıtır kızartma, yoğurt ve nane sosu ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(43, 'Su Mantısı',           175.00, 'Haşlanmış elde yapımı mantı, tereyağlı domates sosu ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(44, 'Mercimek Çorbası',     55.00,  'Klasik kırmızı mercimek çorbası.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(44, 'Tarhana Çorbası',      65.00,  'Anadolu mutfağının klasik tarhanası, tereyağı ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(44, 'Yayla Çorbası',        60.00,  'Yoğurtlu, naneli yayla çorbası.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(45, 'Cacık',                50.00,  'Yoğurt, salatalık, taze nane ve sarımsakla soğuk meze.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(45, 'Haydari',              60.00,  'Süzme yoğurt ve dereotu mezesi.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(45, 'Atom',                 65.00,  'Yoğurt, közlenmiş biber ve sarımsaklı acılı meze.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 46-48 (Hasanpaşa Köftecisi) ──
(46, 'Izgara Köfte (4 Adet)', 220.00, 'El emeği dana köftesi, közde piyaz ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(46, 'Kaşarlı Köfte',        240.00, 'İçi eritilmiş kaşar dolgulu, çıtır dış kabuklu köfte.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(46, 'Soslu Köfte',          230.00, 'Domates ve kekikle pişmiş tencere köfte.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(47, 'Piyaz',                60.00,  'Beyaz fasulye, soğan, sumak ve zeytinyağıyla soğuk piyaz.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(47, 'Çoban Salata',         50.00,  'Klasik Anadolu salatası, taze sebzeler ve limon.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(47, 'Acılı Ezme',           45.00,  'Acılı domates ezmesi, taze biber ve maydanozla.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(48, 'Ayran',                25.00,  'Ev yapımı köpüklü ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(48, 'Şalgam',               28.00,  'Adana usulü acılı şalgam.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(48, 'Su',                   10.00,  '500ml pet şişe.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 49-51 (Çengelköy Çikolatacısı) ──
(49, 'El Yapımı Trüf (5 Adet)', 150.00, 'Karışık trüf çikolata kutusu, fındık ve fıstık dolgulu.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(49, 'Sıcak Çikolata',       85.00,  'Belçika çikolatasından hazırlanan kremalı sıcak çikolata.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(49, 'Nutella Tablası',      120.00, 'Çıtır gofretler eşliğinde fındık kreması tablası.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(50, 'Mocha',                95.00,  'Espresso, sıcak süt ve çikolata sosu kombinasyonu.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(50, 'Espresso',             50.00,  'Tek shot İtalyan espresso.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(50, 'Cappuccino',           75.00,  'Süt köpüklü klasik cappuccino.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(51, 'Çikolatalı Brownie',   105.00, 'Erimiş çikolatalı brownie, dondurma topu ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(51, 'Çikolatalı Sufle',     115.00, 'İçi akan sıcak çikolatalı sufle.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(51, 'Black Forest',         110.00, 'Çikolata, vişne ve krema ile alman pastası.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 52-54 (İdealtepe Izgara) ──
(52, 'Kuzu Şiş',             320.00, 'Terbiyeli, tereyağı ve kekikle pişen kuzu şiş.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(52, 'Tavuk Kanat',          190.00, 'Marine edilmiş baharatlı tavuk kanat ızgarası.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(52, 'Bonfile Şiş',          380.00, 'Yumuşak dana bonfile şiş, sebzeli garnitür ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(53, 'Şakşuka',              75.00,  'Kızartılmış patlıcan, biber, sarımsak ve domates sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(53, 'Acılı Ezme',           65.00,  'Cevizli, nar ekşili acılı meze.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(53, 'Cacık',                55.00,  'Yoğurtlu, naneli serinletici meze.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(54, 'Ayran',                25.00,  'Köpüklü taze ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(54, 'Şalgam',               30.00,  'Acılı geleneksel şalgam.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(54, 'Limonata',             45.00,  'Taze sıkılmış limonata.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 55-57 (Göztepe Makarna) ──
(55, 'Fettuccine Alfredo',   210.00, 'Tavuk, mantar ve parmesan ile kremalı alfredo sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(55, 'Penne Arrabbiata',     180.00, 'Acılı domates sosu, sarımsak ve maydanoz ile.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(55, 'Spaghetti Bolognese',  220.00, 'Geleneksel İtalyan dana ragu sosuyla pişmiş spagetti.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(56, 'Tiramisu',             110.00, 'Mascarpone ve espresso ile İtalyan tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(56, 'Panna Cotta',          95.00,  'Krema bazlı tatlı, orman meyveleri sosu ile.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(56, 'Cantucci',             80.00,  'Bademli toscana kurabiyeleri.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(57, 'Chianti Şarap',        260.00, 'İtalyan toscana bölgesi kırmızı şarap.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(57, 'Pinot Grigio',         240.00, 'Kuru beyaz İtalyan şarabı.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(57, 'Prosecco',             280.00, 'Hafif köpüklü İtalyan şarabı.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 58-60 (Ataşehir Sushico) ──
(58, 'California Roll (8 Adet)', 250.00, 'Yengeç, avokado, salatalık ve susam ile maki.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(58, 'Spicy Tuna Roll',      270.00, 'Acı sosla harmanlanmış ton balığı, salatalık ile.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(58, 'Salmon Avocado',       260.00, 'Taze somon ve avokado ile maki.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(59, 'Sebzeli Noodle',       180.00, 'Karışık sebzeli wok noodle, soya soslu.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(59, 'Tavuklu Noodle',       210.00, 'Tavuk parçaları, sebze ve teriyaki sos ile noodle.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(59, 'Pad Thai',             220.00, 'Karides, fıstık ve lime ile geleneksel Tayland noodle.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(60, 'Yeşil Çay',            45.00,  'Geleneksel sencha yeşil çay.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(60, 'Sake (Soğuk)',         180.00, 'Premium soğuk Japon sake.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(60, 'Bubble Tea',           85.00,  'Tapyokalı süt çayı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 61-63 (Caddebostan Vegan Bistro) ──
(61, 'Mantarlı Risotto',     220.00, 'Vegan parmesan ve karışık mantar ile %100 vegan risotto.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(61, 'Falafel Tabağı',       180.00, 'Çıtır falafel, tahin sos, taze sebze ve bulgur pilavı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(61, 'Karnabahar Şinitzel',  195.00, 'Galeta unu kaplamalı çıtır karnabahar, vegan mayonez ile.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(62, 'Beyond Burger',        260.00, 'Bitki bazlı Beyond Meat köftesi, vegan peynir ve marul.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(62, 'Tofu Burger',          230.00, 'Marine tofu, avokado ve karamelize soğanlı vegan burger.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(62, 'Mantar Burger',        220.00, 'Izgara portobello mantarı, sebze ve vegan sos.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(63, 'Vegan Cheesecake',     130.00, 'Hindistan cevizi sütü ve kaju kreması ile vegan cheesecake.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(63, 'Çikolata Mousse',      110.00, 'Avokado bazlı vegan çikolatalı mousse.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(63, 'Hindistan Cevizi Pudding', 90.00, 'Chia tohumlu, hindistan cevizi sütlü puding.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 64-66 (Suadiye Sushi Master) ──
(64, 'Otoro Nigiri (2 Adet)', 380.00, 'Premium ton balığı yağlı kısmı (otoro) nigiri.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(64, 'Uni Nigiri',           320.00, 'Hokkaido deniz kestanesi nigiri.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(64, 'Sake Nigiri',          240.00, 'Norveç somonu nigiri ikilisi.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(65, 'Salmon Sashimi',       320.00, 'Taze somondan dilimlenmiş 6 parça sashimi.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(65, 'Tuna Sashimi',         340.00, 'Premium ton balığı sashimi tabağı.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(65, 'Mixed Sashimi',        420.00, 'Somon, ton ve levrek karışık sashimi.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(66, 'Dragon Roll',          290.00, 'Tempura karides, avokado ve unagi sos ile.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(66, 'Rainbow Roll',         310.00, 'California rolun üstüne dilimlenmiş çeşit balıklar.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(66, 'Tempura Maki',         260.00, 'Çıtır tempura kaplı karides ve avokadolu maki.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 67-69 (Moda Kahvaltı Evi) ──
(67, 'Serpme Kahvaltı (Kişilik)', 220.00, 'Beş çeşit peynir, zeytin, reçel, bal-kaymak, sıcak yumurta, çay sınırsız.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(67, 'Köy Kahvaltısı',       240.00, 'Köy yumurtası, organik tereyağı, ev yapımı reçeller, taze ekmek.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(67, 'Kuzine Kahvaltı',      280.00, 'Sıcak menemen, sucuklu yumurta, peynir tabağı, taze meyve.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(68, 'Menemen',              130.00, 'Domates, biber, soğan ve yumurta ile klasik menemen.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(68, 'Sucuklu Yumurta',      150.00, 'Tereyağında pişmiş sucuk ve sahanda yumurta.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(68, 'Pastırmalı Yumurta',   170.00, 'Tütsülenmiş pastırma ve sahanda yumurta.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(69, 'Demli Türk Çayı',      18.00,  'Sınırsız demli klasik Türk çayı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(69, 'Türk Kahvesi',         50.00,  'Lokum eşliğinde geleneksel kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(69, 'Sahlep',               65.00,  'Tarçınlı sıcak sahlep.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 70-72 (Bağdat Kokoreççisi) ──
(70, 'Yarım Ekmek Kokoreç',  140.00, 'Kuzu kokoreç, közde pişirilmiş bol baharatlı, yarım ekmek arası.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(70, 'Çeyrek Ekmek Kokoreç', 90.00,  'Atıştırmalık boyutta kokoreç dürümü.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(70, 'Tabakta Kokoreç (200g)', 230.00, 'Doğranmış porsiyon kokoreç, közlenmiş biber ve domates ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(71, 'Kavurma Lavaş',        110.00, 'Kuzu kavurma sarma lavaş.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(71, 'Sucuk Ekmek',          85.00,  'Tereyağlı sucuk ve sıcak ekmek.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(71, 'Tantuni',              115.00, 'Mersin usulü dana tantuni dürümü.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(72, 'Ayran (Büyük)',        35.00,  'Köpüklü büyük boy ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(72, 'Şalgam',               30.00,  'Acılı taze şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(72, 'Kola',                 35.00,  'Buz gibi kutu kola.', '{}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 73-75 (Kadıköy Tacos) ──
(73, 'Carne Asada Taco (3 Adet)', 200.00, 'Marine sığır eti, taze koriander ve lime ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(73, 'Pollo Taco',           180.00, 'Acılı tavuk, avokado ve mısır salsası ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(73, 'Veggie Taco',          160.00, 'Kara fasulye, mısır, biber ve avokado ile vegan tacos.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(74, 'Carne Burrito',        220.00, 'Sığır eti, pirinç, fasulye ve guacamole ile sarma.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(74, 'Chicken Burrito',      200.00, 'Acılı tavuk, koriander pirinci ve salsa ile burrito.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(74, 'Veggie Burrito',       170.00, 'Vegan, kara fasulye ve sebzelerle hazırlanmış sarma.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(75, 'Margarita Cocktail',   190.00, 'Tequila, lime ve triple sec.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(75, 'Horchata',             80.00,  'Pirinç, badem ve tarçın ile geleneksel meksika içeceği.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(75, 'Corona',               90.00,  'Soğuk Corona Extra şişe bira.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 76-78 (Üsküdar Karadeniz Mutfağı) ──
(76, 'Muhlama',              140.00, 'Tereyağı, mısır unu ve Karadeniz peyniriyle pişmiş muhlama.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(76, 'Mıhlama',              135.00, 'Sahan kabında peynirli ve tereyağlı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(76, 'Kuymak',               130.00, 'Karadeniz usulü mısır unu ve peynirli sıcak.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(77, 'Hamsi Tava',           220.00, 'Mısır unu kaplamalı çıtır hamsi tava.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(77, 'Hamsili Pilav',        210.00, 'Soğanlı, üzüm taneli, hamsili Karadeniz pilavı.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(77, 'Hamsi Buğulama',       240.00, 'Sebzeli ve domatesli buğulama hamsi.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(78, 'Karadeniz Pidesi',     85.00,  'Mısır unundan yapılma karadeniz pidesi, balla.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(78, 'Laz Böreği',           120.00, 'Muhallebili, şerbetli özel börek.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(78, 'Kabak Tatlısı',        90.00,  'Cevizli, kaymaklı geleneksel kabak tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 79-81 (Ataşehir Wokery) ──
(79, 'Tavuklu Wok',          220.00, 'Soya soslu, sebzeli wok tavuk, jasmine pilavı eşliğinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(79, 'Sığır Wok',            260.00, 'İnce dilimlenmiş sığır eti, brokoli ve oyster sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(79, 'Karides Wok',          290.00, 'Karides, taze zencefil ve sebzeli wok.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(80, 'Tom Yum',              140.00, 'Acılı, ekşi Tayland karides çorbası.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(80, 'Wonton Çorba',         130.00, 'El yapımı tavuk dolgulu wonton, soya bazlı çorba.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(80, 'Miso Çorbası',         95.00,  'Tofu, deniz yosunu ve miso bazlı geleneksel Japon çorbası.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(81, 'Buharlı Karides Mantısı', 160.00, '5 adet karides dolgulu shumai dim sum.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(81, 'Sebzeli Bao',          110.00, 'Buharda pişmiş sebzeli yumuşak bao.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(81, 'Tavuklu Bao',          130.00, 'Marine tavuk dolgulu bao bun.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 82-84 (Bostancı Kahve Atölyesi) ──
(82, 'V60 Pour Over',        80.00,  'Etiyopya yirgacheffe single-origin V60 demleme.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(82, 'Aeropress',            75.00,  'Kolombiya supremo Aeropress.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(82, 'Cold Brew',            85.00,  '12 saat soğuk demleme, az asitli specialty kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(83, 'Cheesecake (Frambuaz)', 110.00, 'Yanık New York cheesecake, frambuaz sosu.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(83, 'Karamel Latte Cake',   105.00, 'Karamel ve kahve aromalı yumuşak kek.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(83, 'Vegan Brownie',        95.00,  'Vegan tarif, fındıklı koyu kakaolu brownie.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(84, 'Avokadolu Toast',      130.00, 'Ekşi mayalı ekmek üzerinde avokado, fesleğen ve kiraz domates.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(84, 'Eggs Benedict',        160.00, 'İngiliz çöreği, hollandaise sos ve poşe yumurta.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(84, 'Granola Bowl',         110.00, 'Yulaflı granola, taze meyve ve yoğurt.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 85-87 (Maltepe Tükürük Köftecisi) ──
(85, 'Tükürük Köfte (8 Adet)', 220.00, 'Klasik el köftesi, sumaklı soğan ve domates ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(85, 'Acılı Tükürük Köfte',  235.00, 'İsotlu, acılı tükürük köftesi.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(85, 'Pırasalı Köfte',       210.00, 'Pırasalı, baharatlı kuru köfte.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(86, 'Piyaz',                55.00,  'Tükürük köftecisinin klasik fasulye piyazı.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(86, 'Mevsim Salata',        50.00,  'Marul, taze sebze ve sumaklı sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(86, 'Cacık',                40.00,  'Yoğurtlu, naneli klasik cacık.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(87, 'Ayran',                25.00,  'Açık ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(87, 'Şalgam',               28.00,  'Acılı turp suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(87, 'Limonata',             45.00,  'Ev yapımı buzlu limonata.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 88-90 (Erenköy Vegan House) ──
(88, 'Mercimekli Sebze Köfte', 170.00, 'Yeşil mercimek ve sebze ile çıtır vegan köfte.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(88, 'Buddha Bowl',          190.00, 'Kinoa, nohut, avokado, brokoli ve tahin sos ile vegan kase.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(88, 'Sebzeli Lazanya',      210.00, 'Vegan beşamel sosu ve mevsim sebzeleriyle lazanya.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(89, 'Kinoa Salata',         140.00, 'Kinoa, nar, ceviz ve nar ekşili dressing.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(89, 'Avokado Salata',       155.00, 'Avokado, kiraz domates, fesleğen ve limon.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(89, 'Akdeniz Salata',       130.00, 'Roka, zeytin, kuru domates, kapari ve tahin sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(90, 'Vegan Tiramisu',       125.00, 'Hindistan cevizi kreması ve kahveyle vegan tiramisu.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(90, 'Vegan Çikolata Mousse', 110.00, 'Avokado bazlı koyu çikolatalı mousse.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(90, 'Raw Brownie',          95.00,  'Pişmemiş, hurma ve fındıklı raw brownie.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 91-93 (Caddebostan Salata Bar) ──
(91, 'Sezar Salata',         140.00, 'Marul, parmesan, kruton ve klasik sezar sos.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(91, 'Tavuklu Bowl',         170.00, 'Izgara tavuk, kinoa, mevsim sebzeleri ve tahin sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(91, 'Akdeniz Salata',       155.00, 'Yeşillik, zeytin, beyaz peynir, biber ve nar ekşili.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(92, 'Soğuk Domates Çorbası', 80.00,  'Gazpacho — taze domates, salatalık ve fesleğen.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(92, 'Avokado Çorbası',      85.00,  'Soğuk avokado, salatalık ve nane çorbası.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(92, 'Yoğurt Çorbası',       65.00,  'Soğuk yoğurt çorbası, taze nane ile.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(93, 'Yeşil Smoothie',       70.00,  'Ispanak, elma, muz ve zencefil.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(93, 'Kırmızı Smoothie',     75.00,  'Çilek, frambuaz, muz ve süt.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(93, 'Tropikal Smoothie',    78.00,  'Mango, ananas, muz ve hindistan cevizi sütü.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 94-96 (Kozyatağı Antep Lezzetleri) ──
(94, 'Antep Kebabı',         310.00, 'Antep usulü zırh kıyma, isotlu, közlenmiş domates ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(94, 'Beyti',                340.00, 'Sıcak lavaşa sarılmış beyti, yoğurt ve domates sosuyla.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(94, 'Patlıcan Kebabı',      290.00, 'Közde patlıcan ve dana kıyma kebabı.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(95, 'Antep Baklavası',      150.00, 'Antep fıstıklı klasik şerbetli baklava.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(95, 'Künefe',               130.00, 'Hatay peyniri ve fıstıklı sıcak künefe.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(95, 'Burma Kadayıf',        115.00, 'Cevizli, fıstıklı, şerbetli burma kadayıf.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(96, 'Muhammara',            85.00,  'Kırmızı biber, ceviz, nar ekşisi ve isotla.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(96, 'Yuvalama',             95.00,  'Yoğurt, nohut ve küçük köftelerle Antep mezesi.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(96, 'Acuka',                70.00,  'Domates, ceviz, isot ve baharatlarla acılı meze.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 97-99 (Suadiye Brunch Cafe) ──
(97, 'Avokadolu Eggs Benedict', 180.00, 'İngiliz çöreği, avokado, hollandaise ve poşe yumurta.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(97, 'Smoked Salmon Toast',  195.00, 'Çavdar ekmeği üzerinde tütsülenmiş somon ve labne.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(97, 'Tam Brunch Tabağı',    260.00, 'Yumurta, peynir, sucuk, avokado, taze ekmek karışık brunch.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(98, 'Klasik Pancake',       110.00, 'Üç katlı pancake, akçaağaç şurubu ve tereyağı ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(98, 'Belçika Waffle',       125.00, 'Çıtır waffle, çikolata sosu, taze çilek ve krema.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(98, 'French Toast',         105.00, 'Vanilyalı sütle ıslatılmış kızartılmış brioche dilimleri.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(99, 'Taze Portakal Suyu',   55.00,  'Anlık sıkılmış taze portakal suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(99, 'Detoks Suyu',          65.00,  'Salatalık, limon, zencefil ve nane.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(99, 'Latte',                85.00,  'Buharlı sütle hazırlanmış latte.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 100-102 (Beşiktaş Köftecisi) ──
(100, 'Akçaabat Köftesi',    230.00, 'Trabzon usulü çıtır kabuklu, baharatlı köfte.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(100, 'Tekirdağ Köftesi',    220.00, 'Hafif baharatlı, yağlı yumuşak Tekirdağ köftesi.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(100, 'İnegöl Köftesi',      225.00, 'Soğanlı, baharatlı klasik İnegöl köftesi.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(101, 'Pilav Üstü Köfte',    180.00, 'Sade pilav üzerinde 4 adet ızgara köfte.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(101, 'Patates Püresi',      55.00,  'Tereyağlı, kremalı patates püresi.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(101, 'Etli Kuru Fasulye',   140.00, 'Bol etli kuru fasulye, pilav ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(102, 'Ayran',               25.00,  'Köpüklü taze ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(102, 'Şalgam',              28.00,  'Acılı şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(102, 'Soda',                15.00,  'Maden suyu, sade veya limonlu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 103-105 (Taksim Pizzeria Roma) ──
(103, 'Margherita',          220.00, 'Taze mozzarella, fesleğen ve San Marzano domates sosu.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(103, 'Pepperoni',           260.00, 'Acılı pepperoni dilimleri ve mozzarella.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(103, 'Capricciosa',         280.00, 'Mantar, jambon, enginar ve zeytinli klasik İtalyan pizza.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(104, 'Tartufo Pizza',       340.00, 'Trüf yağı, mantar, parmesan ve mozzarella.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(104, 'Burrata Pizza',       320.00, 'Tam burrata, kiraz domates ve fesleğen.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(104, 'Diavola Pizza',       290.00, 'Acılı salam, biber, mozzarella ve oregano.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(105, 'Antipasto Misto',     165.00, 'Karışık İtalyan mezeleri, salam, peynir ve zeytin.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(105, 'Caprese Salata',      135.00, 'Domates, mozzarella, fesleğen ve zeytinyağı.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(105, 'Bruschetta Trio',     115.00, 'Üç çeşit bruschetta — domatesli, mantarlı, prosciutto.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 106-108 (Bakırköy Kahvaltı Evi) ──
(106, 'Köy Kahvaltısı (Kişilik)', 230.00, 'Beş çeşit peynir, organik tereyağı, ev reçelleri, taze ekmek.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(106, 'Edirne Tava Ciğer Kahvaltısı', 280.00, 'Tava ciğer, sahanda yumurta, peynir ve zeytin.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(106, 'Vegan Kahvaltı',      210.00, 'Tofu peyniri, hummus, avokado, badem reçeli, vegan ekmek.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(107, 'Menemen',             130.00, 'Köy yumurtalı klasik menemen.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(107, 'Sucuklu Yumurta',     150.00, 'Tereyağında sucuk ve sahanda yumurta.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(107, 'Pastırmalı Sahan Yumurta', 165.00, 'Tütsülenmiş pastırma ve sahanda yumurta.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(108, 'Demli Çay',           18.00,  'Sınırsız demli klasik çay.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(108, 'Türk Kahvesi',        50.00,  'Lokum eşliğinde geleneksel kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(108, 'Filtre Kahve',        55.00,  'Taze demlenmiş filtre kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 109-111 (Küçükçekmece Et Mangal) ──
(109, 'Antrikot (300g)',     520.00, 'Marbling değeri yüksek dana antrikot, közlenmiş sebze ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(109, 'Kuzu Pirzola',        490.00, 'Marine kuzu pirzola, taze kekik ve sarımsakla.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(109, 'Bonfile (250g)',      450.00, 'Yumuşak dana bonfile, mantar sos seçenekli.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(110, 'Tavuk Kanat',         180.00, 'Marine baharatlı tavuk kanat ızgarası.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(110, 'Tavuk Pirzola',       210.00, 'Tavuk pirzola, közlenmiş biber ve tereyağı.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(110, 'Tavuk Şiş',           195.00, 'Sebze ve tavuk göğsü şiş.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(111, 'Bulgur Pilavı',       55.00,  'Domatesli bulgur pilavı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(111, 'Patates Kızartması',  60.00,  'Çıtır altın patates kızartması.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(111, 'Mevsim Salata',       65.00,  'Marul, salatalık, domates ve zeytinyağı.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 112-114 (Florya Sahil Balık) ──
(112, 'Levrek Izgara',       380.00, 'Taze deniz levreği, limon ve roka ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(112, 'Çupra Buğulama',      350.00, 'Sebzeli çupra buğulama.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(112, 'Lüfer Tava',          410.00, 'Sezonluk taze lüfer balığı, tereyağında.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(113, 'Ahtapot Salata',      190.00, 'Haşlanmış ahtapot, soğan, kapari ve zeytinyağı.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(113, 'Karides Güveç',       260.00, 'Domatesli, kaşarlı karides güvecinde.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(113, 'Patlıcan Salata',     85.00,  'Közlenmiş patlıcan, tahin ve sarımsak.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(114, 'Beyaz Şarap (Kadeh)', 240.00, 'Yerli kuru beyaz şarap.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(114, 'Rakı (35cl)',         320.00, 'Yeni Rakı veya Tekirdağ.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(114, 'Gazoz',               30.00,  'Soğuk gazoz.', '{}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 115-117 (Beyoğlu Vegan Lab) ──
(115, 'Tropikal Buddha Bowl', 195.00, 'Kinoa, mango, avokado, edamame ve tahin sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(115, 'Mexican Bowl',        210.00, 'Kara fasulye, mısır, koriander pirinci ve avokado.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(115, 'Asian Bowl',          200.00, 'Tofu, edamame, esmer pirinç ve sesame dressing.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(116, 'Beyond Burger',       270.00, 'Beyond Meat köftesi, vegan peynir, marul ve özel sos.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(116, 'Falafel Burger',      230.00, 'Çıtır falafel, tahin sos ve roka.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(116, 'Mantar Burger',       240.00, 'Portobello mantar, vegan peynir ve karamelize soğan.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(117, 'Raw Cheesecake',      135.00, 'Pişmemiş kaju bazlı raw cheesecake.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(117, 'Çia Pudding',         100.00, 'Hindistan cevizi sütü ve çia tohumu pudingi.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(117, 'Hurma Topları',       80.00,  'Hurma, badem ve kakaolu raw bites.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 118-120 (Cihangir Specialty Coffee) ──
(118, 'Etiyopya V60',        85.00,  'Yirgacheffe single-origin, çiçeksi tatlar.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(118, 'Kolombiya Aeropress', 80.00,  'Supremo, çikolata ve karamel notaları.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(118, 'Kenya Chemex',        90.00,  'Asitli, narenciye notalı Kenya AA.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(119, 'Flat White',          80.00,  'Çift shot ristretto ve buharla ısıtılmış süt.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(119, 'Cortado',             75.00,  'Espresso ve eşit miktarda buharlı süt.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(119, 'Latte (Yulaflı)',     90.00,  'Yulaf sütü ile vegan latte.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(120, 'Karamel Cheesecake',  115.00, 'Tuzlu karamel sosu üzeri.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(120, 'Brownie',             95.00,  'Klasik çikolatalı brownie.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(120, 'Vegan Granola Cookie', 70.00,  'Yulaflı, fındıklı vegan kurabiye.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 121-123 (Levent Sushi Bar) ──
(121, 'Wagyu Nigiri',        420.00, 'Premium A5 wagyu nigiri, çiy.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(121, 'Hamachi Sashimi',     350.00, 'Sarı kuyruklu balık sashimi tabağı.', '{"Pesketaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(121, 'Omakase Set',         580.00, '12 parça şefin seçimi sushi.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(122, 'Chicken Donburi',     195.00, 'Tavuklu, soya bazlı pirinç kasesi.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(122, 'Salmon Donburi',      220.00, 'Tütsülenmiş somon, avokado ve pirinç.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(122, 'Vegetable Donburi',   165.00, 'Marine sebzeler ve esmer pirinç.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(123, 'Tavuk Yakitori',      170.00, 'Soya soslu marine tavuk şiş.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(123, 'Karaage',             185.00, 'Çıtır kızartılmış tavuk, mayo dip sos.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(123, 'Edamame',             75.00,  'Buharda haşlanmış soya fasulyesi, deniz tuzu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 124-126 (Beşiktaş Mexican Cantina) ──
(124, 'Carnitas Taco (3 Adet)', 220.00, 'Yavaş pişmiş domuz benzeri, koriander ve soğanla.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(124, 'Fish Taco',           240.00, 'Çıtır beyaz balık, kremalı slaw ve lime.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(124, 'Veggie Burrito',      180.00, 'Kara fasulye, mısır, biber ve guacamole.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(125, 'Quesadilla (Tavuk)',  210.00, 'Tortilla arasında tavuk, peynir ve biber.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(125, 'Veggie Quesadilla',   180.00, 'Mantar, biber, soğan ve peynir.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(125, 'Beef Quesadilla',     230.00, 'Yavaş pişmiş sığır eti ve eritilmiş peynir.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(126, 'Klasik Margarita',    200.00, 'Tequila, triple sec ve lime.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(126, 'Frozen Margarita',    220.00, 'Buzlu klasik margarita.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(126, 'Spicy Margarita',     230.00, 'Acı biber infüzyonlu margarita.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 127-129 (Etiler Doğu Mutfağı) ──
(127, 'Kung Pao Tavuk',      230.00, 'Acılı, fıstıklı klasik Sichuan tavuğu.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(127, 'Mapo Tofu',           180.00, 'Acılı fasulye sosu ile baharatlı tofu.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(127, 'Sweet Sour Pork',     250.00, 'Tatlı ekşi sosla pişmiş çıtır kıyma.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(128, 'Pad Thai',            220.00, 'Karides, fıstık, lime ile geleneksel Tayland noodle.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(128, 'Green Curry',         210.00, 'Hindistan cevizi sütlü yeşil köri, tavuk veya tofu.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(128, 'Tom Kha Gai',         140.00, 'Hindistan cevizli, limonotlu tavuk çorbası.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(129, 'Bubble Tea',          85.00,  'Tapyokalı süt çayı, klasik.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(129, 'Yeşil Çay',           45.00,  'Sencha veya genmaicha seçenekli.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(129, 'Tayland Çayı',        70.00,  'Sütlü, tatlı geleneksel Tayland çayı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 130-132 (Bebek Brunch & More) ──
(130, 'Avokado Toast',       145.00, 'Ekşi mayalı ekmek, ezilmiş avokado, kiraz domates ve fesleğen.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(130, 'Salmon Bagel',        180.00, 'Bagel, krem peynir, tütsülenmiş somon ve dereotu.', '{"Pesketaryen"}', array_fill(0, ARRAY[3072])::vector),
(130, 'Vegan Brunch',        195.00, 'Tofu scramble, kavrulmuş sebzeler, hummus ve tam buğday ekmek.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(131, 'Eggs Benedict',       165.00, 'Klasik İngiliz çöreği, hollandaise ve poşe yumurta.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(131, 'Shakshuka',           150.00, 'Domates, biber sosu içinde pişmiş yumurtalar.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(131, 'Omlet (Mantar)',      130.00, 'Üç yumurta, taze mantar, peynir ve fesleğen.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(132, 'Yeşil Smoothie',      75.00,  'Ispanak, salatalık, elma ve zencefil.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(132, 'Berry Smoothie',      80.00,  'Karışık böğürtlengiller, muz ve süt.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(132, 'Taze Portakal Suyu',  60.00,  'Anlık sıkma portakal suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 133-135 (Karaköy Kokoreçhanesi) ──
(133, 'Yarım Ekmek Kokoreç', 145.00, 'İzmir usulü kokoreç, bol baharatlı yarım ekmek.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(133, 'Çeyrek Kokoreç',      90.00,  'Atıştırmalık çeyrek ekmek arası kokoreç.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(133, 'Tabakta Kokoreç',     220.00, 'Doğranmış kokoreç, közlenmiş biber.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(134, 'Midye Dolma (10)',    100.00, 'Baharatlı pirinç dolgulu midye.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(134, 'Tantuni',             120.00, 'Sıcak yağda kavrulan dana eti, lavaş arası.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(134, 'Kavurma Dürüm',       115.00, 'Kuzu kavurma, soğan ve maydanozla dürüm.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(135, 'Şalgam',              30.00,  'Buz gibi şalgam suyu.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(135, 'Ayran',               25.00,  'Köpüklü ayran.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(135, 'Bira',                70.00,  'Soğuk şişe bira.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 136-138 (Galata Kahve Sanatı) ──
(136, 'Klasik Türk Kahvesi', 55.00,  'Bakır cezvede pişirilmiş, lokum eşliğinde.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(136, 'Menengiç Kahvesi',    65.00,  'Antep menengiç tohumundan kafeinsiz alternatif.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(136, 'Damla Sakızlı Kahve', 70.00,  'Sakız aromalı geleneksel kahve.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(137, 'Espresso',            50.00,  'Tek shot İtalyan espresso.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(137, 'Cappuccino',          80.00,  'Süt köpüklü klasik cappuccino.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(137, 'Latte',               85.00,  'Yumuşak süt aromalı latte.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(138, 'Lokum',               35.00,  'Karışık çeşit Türk lokumu, beş parça.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(138, 'Pestil',              40.00,  'Cevizli ev yapımı pestil.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(138, 'Künefe',              125.00, 'Hatay peyniri ile sıcak künefe.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 139-141 (Şişli Kebap Sarayı) ──
(139, 'Adana Şiş',           300.00, 'Acılı kıyma kebabı, közlenmiş domates ve biber ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(139, 'Kuzu Şiş',            340.00, 'Marine kuzu şiş, baharatlı pirinç pilavı ile.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(139, 'Tavuk Şiş',           240.00, 'Marine tavuk göğsü şiş.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(140, 'Haydari',             65.00,  'Süzme yoğurt, dereotu ve sarımsak.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(140, 'Acılı Ezme',          60.00,  'Cevizli, nar ekşili acılı meze.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(140, 'Patlıcan Salata',     70.00,  'Közlenmiş patlıcan ve tahin.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(141, 'Künefe',              130.00, 'Hatay peyniri ve fıstıklı sıcak künefe.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(141, 'Fıstıklı Baklava',    140.00, 'Antep fıstıklı şerbetli baklava.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(141, 'Sütlaç',              80.00,  'Fırın sütlaç, tarçın ile.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 142-144 (Beyoğlu Sokak Tatlıcısı) ──
(142, 'Tulumba',             65.00,  'Şerbetli, tıkır tıkır çıtır tulumba tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(142, 'Lokma',               55.00,  'Sıcak şerbetli lokma, tarçın serpilmiş.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(142, 'Kazandibi',           80.00,  'Tabanı kızartılmış sütlü tatlı.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(143, 'Maraş Dondurması',    85.00,  'Sakızlı, salepli maraş dondurması.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(143, 'Sade Dondurma',       70.00,  'Vanilya, çikolata veya çilek.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(143, 'Kestaneli Dondurma',  90.00,  'Bursa kestaneli klasik dondurma.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(144, 'Salep',               65.00,  'Tarçınlı sıcak salep.', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(144, 'Boza',                45.00,  'Geleneksel beyaz boza, leblebi ile.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(144, 'Sıcak Çikolata',      75.00,  'Belçika çikolatasından kremalı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 145-147 (Yeşilköy Vegan Garden) ──
(145, 'Falafel Bowl',        180.00, 'Çıtır falafel, hummus, tabule ve tahin sos.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(145, 'Tofu Stir-Fry Bowl',  195.00, 'Marine tofu, brokoli, edamame ve esmer pirinç.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(145, 'Mantar Bowl',         185.00, 'Karışık mantar, kinoa ve tahin sos.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(146, 'Vegan Margherita',    220.00, 'Vegan mozzarella ve fesleğen ile pizza.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(146, 'Mantarlı Vegan Pizza', 240.00, 'Karışık mantar, vegan peynir ve trüf yağı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(146, 'Sebzeli Vegan Pizza', 230.00, 'Mevsim sebzeleriyle vegan pizza.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(147, 'Vegan Cheesecake',    130.00, 'Kaju ve hindistan cevizi sütüyle vegan cheesecake.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(147, 'Vegan Brownie',       105.00, 'Hurma ve fındıklı vegan brownie.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(147, 'Çia Pudding',         95.00,  'Hindistan cevizi sütlü çia pudingi, taze meyve ile.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),

-- ── Cat 148-150 (Bakırköy Anatolian Grill) ──
(148, 'Erzurum Cağ Kebabı',  310.00, 'Yatay döner sistemi ile pişen kuzu cağ kebabı.', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(148, 'Konya Etli Ekmek',    230.00, 'Konya usulü uzun, ince hamur, dana kıyma ile.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(148, 'Bursa İskender',      290.00, 'Tereyağlı klasik İskender kebabı.', '{"Helal"}', array_fill(0, ARRAY[3072])::vector),
(149, 'Sivas Madımak',       95.00,  'Yöresel sivas madımak otu pilavı.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(149, 'Mardin Hummusu',      85.00,  'Mardin tarzı tahinli, sarımsaklı hummus.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector),
(149, 'Hatay Zeytin Salatası', 80.00,  'Yeşil zeytin, nar ekşisi, ceviz ve isot.', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[3072])::vector),
(150, 'Antep Baklavası',     145.00, 'Antep fıstıklı şerbetli baklava.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(150, 'Şanlıurfa Şıllığı',   105.00, 'Cevizli, şerbetli urfa tatlısı.', '{"Vejetaryen"}', array_fill(0, ARRAY[3072])::vector),
(150, 'Tarsus Cezeryesi',    75.00,  'Havuçlu, fıstıklı, şerbetli yöresel tatlı.', '{"Vegan"}', array_fill(0, ARRAY[3072])::vector);

-- 7. Insert Green Menu Items (10 items, ID'ler yeni dağılıma uygun)
INSERT INTO green_menu (item_id, quantity, discounted_price, expiration_time) VALUES
(2,   5, 150.00, CURRENT_TIMESTAMP + INTERVAL '2 hours'),
(15,  3, 80.00,  CURRENT_TIMESTAMP + INTERVAL '3 hours'),
(45,  4, 100.00, CURRENT_TIMESTAMP + INTERVAL '1 day'),
(82, 10, 50.00,  CURRENT_TIMESTAMP + INTERVAL '5 hours'),
(120, 6, 70.00,  CURRENT_TIMESTAMP + INTERVAL '4 hours'),
(195, 2, 200.00, CURRENT_TIMESTAMP + INTERVAL '6 hours'),
(245, 3, 120.00, CURRENT_TIMESTAMP + INTERVAL '2 hours'),
(310, 8, 90.00,  CURRENT_TIMESTAMP + INTERVAL '3 hours'),
(385, 5, 180.00, CURRENT_TIMESTAMP + INTERVAL '1 hour'),
(430, 4, 100.00, CURRENT_TIMESTAMP + INTERVAL '2 hours');

-- 8. Insert Favorites
INSERT INTO favorite (user_id, target_id, type) VALUES
(5, 1,  'Restaurant'), (5, 5,  'MenuItem'), (5, 12, 'Restaurant'),
(6, 2,  'Restaurant'), (6, 17, 'MenuItem'),
(7, 3,  'Restaurant'), (7, 23, 'MenuItem'),
(8, 4,  'Restaurant'), (8, 45, 'MenuItem'), (8, 5, 'Restaurant'),
(9, 20, 'Restaurant'), (9, 78, 'MenuItem'),
(5, 25, 'Restaurant'), (6, 39, 'Restaurant'),
(7, 145, 'MenuItem'), (8, 220, 'MenuItem');

-- 9. Insert Friend Rooms
INSERT INTO friend_room (creator_id, qr_code) VALUES
(5, 'ROOM_QR_MOCK_12345'),
(6, 'ROOM_QR_MOCK_67890');

-- 10. Insert Room Members
INSERT INTO room_member (room_id, user_id, individual_preferences) VALUES
(1, 5, '{"dietary": ["Helal"], "max_budget": 500}'),
(1, 7, '{"dietary": [], "max_budget": 300}'),
(1, 8, '{"dietary": ["Vejetaryen"], "max_budget": 400}'),
(2, 6, '{"dietary": ["Vegan"], "max_budget": 600}'),
(2, 9, '{"dietary": ["Pesketaryen"], "max_budget": 800}');

-- 11. Insert Reviews
INSERT INTO review (user_id, target_id, rating_score, comment) VALUES
(5, 1,  5, 'Burgerler harikaydı, kesinlikle tavsiye ederim!'),
(6, 2,  4, 'Kebap lezzetliydi ama servis biraz yavaştı.'),
(7, 3,  5, 'Balıklar çok taze, mezeler efsane.'),
(8, 4,  4, 'Pideler çıtır çıtır, malzemesi bol.'),
(9, 20, 5, 'Sushiler çok başarılı, ambiyans süper.'),
(5, 12, 5, 'Pizzalar odun ateşinde pişmiş, çok lezzetli.'),
(6, 21, 5, 'Vegan menü çok zengin, beyond burger müthiş!'),
(7, 27, 4, 'Asya wok lezzetleri taze ve baharatlı.'),
(8, 35, 5, 'Taksim Pizzeria''nın burrata pizzası inanılmaz.'),
(9, 40, 5, 'Cihangir kahvesi specialty'') gerçek Etiyopya tadı.');
