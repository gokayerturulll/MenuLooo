-- Migration: 002_seed_mock_data
-- Description: Seed realistic mock data for MenuLo

-- 1. Clean existing data
TRUNCATE TABLE "restaurant" RESTART IDENTITY CASCADE;
TRUNCATE TABLE "user" RESTART IDENTITY CASCADE;

-- 2. Insert Users (1 Admin, 3 Owners, 5 Customers)
INSERT INTO "user" (role, username, email, phone_number, password_hash, location) VALUES
('Admin', 'admin_user', 'admin@menulo.com', '+905550000001', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.02, 40.99), 4326)),
('Owner', 'owner_ahmet', 'ahmet@restaurant.com', '+905550000002', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.03, 40.98), 4326)),
('Owner', 'owner_ayse', 'ayse@restaurant.com', '+905550000003', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.10, 40.97), 4326)),
('Owner', 'owner_mehmet', 'mehmet@restaurant.com', '+905550000004', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.05, 41.00), 4326)),
('Customer', 'cust_ali', 'ali@gmail.com', '+905550000005', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.025, 40.985), 4326)),
('Customer', 'cust_zeynep', 'zeynep@gmail.com', '+905550000006', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.09, 40.96), 4326)),
('Customer', 'cust_can', 'can@gmail.com', '+905550000007', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.04, 40.99), 4326)),
('Customer', 'cust_elif', 'elif@gmail.com', '+905550000008', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.11, 40.975), 4326)),
('Customer', 'cust_burak', 'burak@gmail.com', '+905550000009', 'hash_placeholder', ST_SetSRID(ST_MakePoint(29.01, 41.01), 4326));

-- 2. Insert Restaurants (Exactly 20 in Istanbul Anatolian Side)
INSERT INTO restaurant (owner_id, business_name, address, location_point, work_hours) VALUES
(2, 'Moda Burger', 'Caferağa Mah. Moda Cad. No: 12, Kadıköy', ST_SetSRID(ST_MakePoint(29.0251, 40.9852), 4326), '{"open": "10:00", "close": "23:00"}'),
(3, 'Ataşehir Kebap', 'Kayışdağı Mah. Uslu Sok. No: 5, Ataşehir', ST_SetSRID(ST_MakePoint(29.1411, 40.9785), 4326), '{"open": "11:00", "close": "22:00"}'),
(4, 'Bostancı Balıkçısı', 'Bostancı Mah. Bağdat Cad. No: 200, Kadıköy', ST_SetSRID(ST_MakePoint(29.0945, 40.9531), 4326), '{"open": "12:00", "close": "00:00"}'),
(2, 'Maltepe Pidecisi', 'Yalı Mah. Turgut Özal Bulvarı No: 10, Maltepe', ST_SetSRID(ST_MakePoint(29.1356, 40.9234), 4326), '{"open": "10:00", "close": "22:00"}'),
(3, 'Üsküdar Çaycısı', 'Mimar Sinan Mah. Hakimiyet-i Milliye Cad., Üsküdar', ST_SetSRID(ST_MakePoint(29.0152, 41.0267), 4326), '{"open": "08:00", "close": "23:00"}'),
(4, 'Kadıköy Midye', 'Osmanağa Mah. Söğütlüçeşme Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0305, 40.9912), 4326), '{"open": "12:00", "close": "02:00"}'),
(2, 'Barbaros Kahve', 'Barbaros Mah. Ihlamur Bulvarı, Ataşehir', ST_SetSRID(ST_MakePoint(29.1023, 40.9956), 4326), '{"open": "07:00", "close": "20:00"}'),
(3, 'Suadiye Steakhouse', 'Suadiye Mah. Bağdat Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0812, 40.9623), 4326), '{"open": "12:00", "close": "23:30"}'),
(4, 'İçerenköy Döner', 'İçerenköy Mah. Prof. Dr. Necmettin Erbakan Cad., Ataşehir', ST_SetSRID(ST_MakePoint(29.1124, 40.9756), 4326), '{"open": "11:00", "close": "21:00"}'),
(2, 'Altıntepe Pastanesi', 'Altıntepe Mah. Minibüs Yolu, Maltepe', ST_SetSRID(ST_MakePoint(29.1034, 40.9451), 4326), '{"open": "07:00", "close": "21:00"}'),
(3, 'Kalamış Brasserie', 'Fenerbahçe Mah. Kalamış Fener Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0398, 40.9745), 4326), '{"open": "09:00", "close": "00:00"}'),
(4, 'Kozyatağı Pizzeria', 'Kozyatağı Mah. Bayar Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0965, 40.9732), 4326), '{"open": "11:30", "close": "22:30"}'),
(2, 'Kuzguncuk Fırını', 'Kuzguncuk Mah. İcadiye Cad., Üsküdar', ST_SetSRID(ST_MakePoint(29.0315, 41.0367), 4326), '{"open": "06:00", "close": "19:00"}'),
(3, 'Acıbadem Tatlıcısı', 'Acıbadem Mah. Acıbadem Cad., Üsküdar', ST_SetSRID(ST_MakePoint(29.0456, 41.0023), 4326), '{"open": "08:00", "close": "22:00"}'),
(4, 'Işıklar Mantı', 'Küçükbakkalköy Mah. Işıklar Cad., Ataşehir', ST_SetSRID(ST_MakePoint(29.1154, 40.9821), 4326), '{"open": "10:00", "close": "21:30"}'),
(2, 'Hasanpaşa Köftecisi', 'Hasanpaşa Mah. Kurbağalıdere Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0387, 40.9934), 4326), '{"open": "11:00", "close": "22:00"}'),
(3, 'Çengelköy Çikolatacısı', 'Çengelköy Mah. Çengelköy Cad., Üsküdar', ST_SetSRID(ST_MakePoint(29.0521, 41.0501), 4326), '{"open": "09:00", "close": "23:00"}'),
(4, 'İdealtepe Izgara', 'İdealtepe Mah. Rıfkı Tongsir Cad., Maltepe', ST_SetSRID(ST_MakePoint(29.1235, 40.9387), 4326), '{"open": "12:00", "close": "23:00"}'),
(2, 'Göztepe Makarna', 'Göztepe Mah. Tütüncü Mehmet Efendi Cad., Kadıköy', ST_SetSRID(ST_MakePoint(29.0645, 40.9781), 4326), '{"open": "11:30", "close": "22:00"}'),
(3, 'Ataşehir Sushico', 'Atatürk Mah. Ataşehir Bulvarı, Ataşehir', ST_SetSRID(ST_MakePoint(29.1213, 40.9912), 4326), '{"open": "12:00", "close": "23:00"}');

-- 3. Insert Menus (1 per restaurant)
INSERT INTO menu (restaurant_id) VALUES
(1), (2), (3), (4), (5), (6), (7), (8), (9), (10),
(11), (12), (13), (14), (15), (16), (17), (18), (19), (20);

-- 4. Insert Categories (2 per menu)
INSERT INTO category (menu_id, name) VALUES
(1, 'Burgerler'), (1, 'İçecekler'),
(2, 'Kebaplar'), (2, 'Tatlılar'),
(3, 'Deniz Ürünleri'), (3, 'Mezeler'),
(4, 'Pideler'), (4, 'Salatalar'),
(5, 'Çaylar'), (5, 'Atıştırmalıklar'),
(6, 'Midyeler'), (6, 'İçecekler'),
(7, 'Kahveler'), (7, 'Tatlılar'),
(8, 'Izgara Etler'), (8, 'Şaraplar'),
(9, 'Dönerler'), (9, 'İçecekler'),
(10, 'Pastalar'), (10, 'Sıcak İçecekler'),
(11, 'Ana Yemekler'), (11, 'Kokteyller'),
(12, 'Pizzalar'), (12, 'Başlangıçlar'),
(13, 'Unlu Mamuller'), (13, 'Çay & Kahve'),
(14, 'Sütlü Tatlılar'), (14, 'Şerbetli Tatlılar'),
(15, 'Mantılar'), (15, 'Çorbalar'),
(16, 'Köfteler'), (16, 'Piyaz ve Salata'),
(17, 'Özel Çikolatalar'), (17, 'Kahveler'),
(18, 'Izgara Çeşitleri'), (18, 'Mezeler'),
(19, 'Makarnalar'), (19, 'İtalyan Tatlıları'),
(20, 'Sushi Rolls'), (20, 'Noodle Çeşitleri');

-- 5. Insert Menu Items (2 per category)
INSERT INTO menu_item (category_id, name, price, description, dietary_tags, embedding) VALUES
(1, 'Klasik Burger', 180.00, 'Dana köfte, marul, domates, turşu', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(1, 'Cheeseburger', 210.00, 'Dana köfte, cheddar peyniri, marul, domates', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(2, 'Kutu Kola', 40.00, 'Soğuk kutu kola', '{}', array_fill(0, ARRAY[1536])::vector),
(2, 'Ev Yapımı Limonata', 55.00, 'Taze sıkılmış limonata', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(3, 'Adana Kebap', 280.00, 'Zırh kıyması acılı kebap', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(3, 'Urfa Kebap', 280.00, 'Zırh kıyması acısız kebap', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(4, 'Künefe', 120.00, 'Özel peynirli sıcak künefe', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(4, 'Sütlaç', 80.00, 'Fırın sütlaç', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(5, 'Izgara Levrek', 350.00, 'Taze deniz levreği', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(5, 'Kalamar Tava', 220.00, 'Çıtır kalamar tava ve tarator sos', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(6, 'Haydari', 70.00, 'Süzme yoğurtlu meze', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(6, 'Fava', 70.00, 'Zeytinyağlı fava', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(7, 'Kıymalı Pide', 160.00, 'Özel baharatlı kıymalı pide', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(7, 'Kaşarlı Pide', 150.00, 'Bol kaşarlı pide', '{"Vejetaryen", "Helal"}', array_fill(0, ARRAY[1536])::vector),
(8, 'Çoban Salata', 80.00, 'Taze domates ve salatalık', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(8, 'Gavurdağı Salata', 110.00, 'Cevizli ve nar ekşili salata', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(9, 'Demleme Çay', 20.00, 'İnce belli bardakta Rize çayı', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(9, 'Bitki Çayı', 35.00, 'Kış çayı', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(10, 'Simit', 15.00, 'Sokak simidi', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(10, 'Kaşarlı Tost', 60.00, 'Tam buğday ekmeğine tost', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(11, 'Midye Dolma (10 Adet)', 100.00, 'Baharatlı pirinç dolgulu midye', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(11, 'Midye Tava', 180.00, 'Tarator soslu midye tava', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(12, 'Şalgam Suyu', 30.00, 'Acılı şalgam', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(12, 'Ayran', 25.00, 'Açık köpüklü ayran', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(13, 'Filtre Kahve', 70.00, 'Taze demlenmiş Arabica', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(13, 'Latte', 85.00, 'Sıcak sütlü espresso', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(14, 'Brownie', 110.00, 'Cevizli ıslak brownie', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(14, 'San Sebastian', 130.00, 'Yanık cheesecake', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(15, 'Lokum Antrikot', 650.00, 'Yumuşak dilimlenmiş antrikot', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(15, 'Dallas Steak', 750.00, 'Kemikli dana pirzola', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(16, 'Kırmızı Şarap', 250.00, 'Yerli kırmızı şarap', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(16, 'Beyaz Şarap', 250.00, 'Yerli beyaz şarap', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(17, 'Porsiyon Döner', 240.00, 'Yaprak döner', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(17, 'İskender', 290.00, 'Tereyağlı İskender kebap', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(18, 'Kutu Ayran', 25.00, 'Kutu ayran', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(18, 'Su', 10.00, 'Pet şişe su', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(19, 'Çilekli Pasta', 90.00, 'Taze çilekli yaş pasta', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(19, 'Profiterol', 85.00, 'Özel çikolata soslu profiterol', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(20, 'Türk Kahvesi', 50.00, 'Orta kavrulmuş Türk kahvesi', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(20, 'Sahlep', 75.00, 'Tarçınlı kış içeceği', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(21, 'Izgara Somon', 420.00, 'Mevsim yeşillikleri ile', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(21, 'Tavuk Şinitzel', 280.00, 'Patates salatası ile', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(22, 'Mojito', 220.00, 'Taze naneli mojito', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(22, 'Margarita', 240.00, 'Klasik margarita', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(23, 'Margherita', 210.00, 'İnce hamur, domates sos, mozzarella', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(23, 'Pepperoni', 250.00, 'İtalyan sucuğu ve mozzarella', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(24, 'Sarımsaklı Ekmek', 70.00, 'Fırınlanmış sarımsaklı ekmek', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(24, 'Bruschetta', 90.00, 'Domatesli ve fesleğenli kızarmış ekmek', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(25, 'Ekşi Mayalı Ekmek', 45.00, 'Artizan ekşi mayalı tam buğday ekmek', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(25, 'Zeytinli Açma', 25.00, 'Taze zeytinli puf açma', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(26, 'Siyah Çay', 15.00, 'Bardak çay', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(26, 'Filtre Kahve', 55.00, 'Taze demlenmiş', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(27, 'Kazandibi', 75.00, 'Kızarmış sütlü tatlı', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(27, 'Tavukgöğsü', 75.00, 'Gerçek tavuk etiyle yapılan sütlü tatlı', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(28, 'Fıstıklı Baklava', 140.00, 'Antep fıstıklı klasik baklava', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(28, 'Şöbiyet', 150.00, 'Kaymaklı şöbiyet', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(29, 'Klasik Mantı', 180.00, 'Sarımsaklı yoğurt ve özel soslu', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(29, 'Çıtır Mantı', 190.00, 'Kızarmış çıtır mantı', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(30, 'Mercimek Çorbası', 60.00, 'Süzme mercimek çorbası', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(30, 'Ezogelin Çorbası', 65.00, 'Klasik ezogelin', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(31, 'Izgara Köfte', 220.00, 'Piyaz ile birlikte', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(31, 'Kaşarlı Köfte', 240.00, 'İçi kaşar dolgulu köfte', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(32, 'Piyaz', 60.00, 'Fasulye piyazı', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(32, 'Çoban Salata', 50.00, 'Taze mevsim salata', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(33, 'El Yapımı Trüf', 150.00, 'Karışık trüf çikolata kutusu', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(33, 'Sıcak Çikolata', 85.00, 'Gerçek Belçika çikolatasından', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(34, 'Americano', 60.00, 'Sıcak su ve espresso', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(34, 'Espresso', 50.00, 'Tek shot espresso', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(35, 'Kuzu Şiş', 320.00, 'Terbiyeli kuzu şiş', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(35, 'Tavuk Kanat', 190.00, 'Soslu tavuk kanat', '{"Helal", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(36, 'Şakşuka', 75.00, 'Kızarmış patlıcan ve domates sos', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(36, 'Acılı Ezme', 65.00, 'Nar ekşili cevizli ezme', '{"Vegan", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(37, 'Fettuccine Alfredo', 210.00, 'Tavuklu ve mantarlı kremalı makarna', '{"Helal"}', array_fill(0, ARRAY[1536])::vector),
(37, 'Penne Arrabbiata', 180.00, 'Acılı domates soslu', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(38, 'Tiramisu', 110.00, 'Klasik İtalyan tiramisu', '{"Vejetaryen"}', array_fill(0, ARRAY[1536])::vector),
(38, 'Panna Cotta', 95.00, 'Orman meyveli sos ile', '{"Vejetaryen", "Glutensiz"}', array_fill(0, ARRAY[1536])::vector),
(39, 'California Roll', 250.00, 'Yengeç, avokado, salatalık', '{"Pesketaryen"}', array_fill(0, ARRAY[1536])::vector),
(39, 'Spicy Tuna Roll', 270.00, 'Acı soslu ton balığı', '{"Pesketaryen"}', array_fill(0, ARRAY[1536])::vector),
(40, 'Sebzeli Noodle', 180.00, 'Karışık sebzeli wok noodle', '{"Vegan"}', array_fill(0, ARRAY[1536])::vector),
(40, 'Tavuklu Noodle', 210.00, 'Tavuklu ve sebzeli wok noodle', '{"Helal"}', array_fill(0, ARRAY[1536])::vector);

-- 6. Insert Green Menu Items (10 items)
INSERT INTO green_menu (item_id, quantity, discounted_price, expiration_time) VALUES
(2, 5, 150.00, CURRENT_TIMESTAMP + INTERVAL '2 hours'),
(5, 3, 200.00, CURRENT_TIMESTAMP + INTERVAL '3 hours'),
(15, 10, 80.00, CURRENT_TIMESTAMP + INTERVAL '1 day'),
(23, 2, 120.00, CURRENT_TIMESTAMP + INTERVAL '5 hours'),
(34, 6, 80.00, CURRENT_TIMESTAMP + INTERVAL '4 hours'),
(48, 4, 150.00, CURRENT_TIMESTAMP + INTERVAL '6 hours'),
(55, 3, 100.00, CURRENT_TIMESTAMP + INTERVAL '2 hours'),
(61, 8, 140.00, CURRENT_TIMESTAMP + INTERVAL '3 hours'),
(69, 5, 220.00, CURRENT_TIMESTAMP + INTERVAL '1 hour'),
(77, 4, 180.00, CURRENT_TIMESTAMP + INTERVAL '2 hours');

-- 7. Insert Favorites
INSERT INTO favorite (user_id, target_id, type) VALUES
(5, 1, 'Restaurant'), (5, 5, 'MenuItem'), (5, 12, 'Restaurant'),
(6, 2, 'Restaurant'), (6, 17, 'MenuItem'),
(7, 3, 'Restaurant'), (7, 23, 'MenuItem'),
(8, 4, 'Restaurant'), (8, 45, 'MenuItem'), (8, 5, 'Restaurant'),
(9, 20, 'Restaurant'), (9, 78, 'MenuItem');

-- 8. Insert Friend Rooms (2 rooms)
INSERT INTO friend_room (creator_id, qr_code) VALUES
(5, 'ROOM_QR_MOCK_12345'),
(6, 'ROOM_QR_MOCK_67890');

-- 9. Insert Room Members
INSERT INTO room_member (room_id, user_id, individual_preferences) VALUES
(1, 5, '{"dietary": ["Helal"], "max_budget": 500}'),
(1, 7, '{"dietary": [], "max_budget": 300}'),
(1, 8, '{"dietary": ["Vejetaryen"], "max_budget": 400}'),
(2, 6, '{"dietary": ["Vegan"], "max_budget": 600}'),
(2, 9, '{"dietary": ["Pesketaryen"], "max_budget": 800}');

-- 10. Insert Reviews
INSERT INTO review (user_id, target_id, rating_score, comment) VALUES
(5, 1, 5, 'Burgerler harikaydı, kesinlikle tavsiye ederim!'),
(6, 2, 4, 'Kebap lezzetliydi ama servis biraz yavaştı.'),
(7, 3, 5, 'Balıklar çok taze, mezeler efsane.'),
(8, 4, 4, 'Pideler çıtır çıtır, malzemesi bol.'),
(9, 20, 5, 'Sushiler çok başarılı, ambiyans süper.'),
(5, 12, 5, 'Pizzalar odun ateşinde pişmiş, çok lezzetli.'),
(6, 15, 4, 'Steak çok iyi pişmişti, şarap menüsü geniş.'),
(7, 8, 5, 'Kahveleri çok taze, tatlıları da fena değil.');
