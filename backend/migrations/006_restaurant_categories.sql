-- 006_restaurant_categories.sql
-- restaurant tablosuna categories text[] kolonu ekler.
-- 50 restoranın tamamı tek tek, isim bazında açık şekilde etiketlendi.
-- iOS kategorileriyle birebir eşleşir:
--   Pizza, Hamburger, Salata, Sushi, Steak, Döner,
--   Makarna, Çorba, Tatlı, Deniz Ürünleri, Ramen, Vegan, Kahve
--
-- Çalıştırma: psql $DATABASE_URL -f migrations/006_restaurant_categories.sql

BEGIN;

-- 1. Kolon ekle (idempotent)
ALTER TABLE restaurant
    ADD COLUMN IF NOT EXISTS categories TEXT[] NOT NULL DEFAULT '{}';

-- 2. GIN index — && ve @> operatörleri için zorunlu
CREATE INDEX IF NOT EXISTS idx_restaurant_categories
    ON restaurant USING GIN (categories);

-- 3. Önce hepsini sıfırla (tekrar çalıştırılınca çift kategori girmesin)
UPDATE restaurant SET categories = '{}';

-- ─────────────────────────────────────────────────────────────────────────────
-- Anadolu Yakası — Original 20
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE restaurant SET categories = ARRAY['Hamburger']
    WHERE business_name = 'Moda Burger';
-- Hamburger: burger menüsü ağırlıklı, hepsi bu.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Ataşehir Kebap';
-- Döner: adı zaten kebap, Türk ızgara mutfağı.

UPDATE restaurant SET categories = ARRAY['Deniz Ürünleri']
    WHERE business_name = 'Bostancı Balıkçısı';
-- Deniz Ürünleri: balıkçı = seafood, tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Maltepe Pidecisi';
-- Döner: pide Türk mutfağı. Pizza DEĞİL — pide hamur üstü et/peynir, kebap ailesinden.

UPDATE restaurant SET categories = ARRAY['Kahve', 'Tatlı']
    WHERE business_name = 'Üsküdar Çaycısı';
-- Kahve + Tatlı: çay evi her zaman kurabiye/pasta da sunar; Kahve kategorisi çay evini de kapsar.

UPDATE restaurant SET categories = ARRAY['Deniz Ürünleri']
    WHERE business_name = 'Kadıköy Midye';
-- Deniz Ürünleri: midye = kabuklu deniz ürünü. Önceki migration'da yanlışlıkla Döner'e girmişti.

UPDATE restaurant SET categories = ARRAY['Kahve', 'Tatlı']
    WHERE business_name = 'Barbaros Kahve';
-- Kahve + Tatlı: kahvehane her zaman kek/pasta/kurabiye de sunar.

UPDATE restaurant SET categories = ARRAY['Steak']
    WHERE business_name = 'Suadiye Steakhouse';
-- Steak: isim bizzat steakhouse.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'İçerenköy Döner';
-- Döner: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Tatlı']
    WHERE business_name = 'Altıntepe Pastanesi';
-- Tatlı: pastane = cake/pastry odaklı.

UPDATE restaurant SET categories = ARRAY['Steak', 'Makarna', 'Salata']
    WHERE business_name = 'Kalamış Brasserie';
-- Steak + Makarna + Salata: Avrupa brasserie menüsü — biftek, pasta ve salata üçlüsü standarttır.

UPDATE restaurant SET categories = ARRAY['Pizza']
    WHERE business_name = 'Kozyatağı Pizzeria';
-- Pizza: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Tatlı']
    WHERE business_name = 'Kuzguncuk Fırını';
-- Tatlı: fırın = ekmek + börek + simit + pasta; tatlı kategorisi en yakın.

UPDATE restaurant SET categories = ARRAY['Tatlı']
    WHERE business_name = 'Acıbadem Tatlıcısı';
-- Tatlı: adında bile var.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Işıklar Mantı';
-- Döner: mantı Türk mutfağı; ayrı kategori yok. Döner en yakın (Türk ana yemeği).

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Hasanpaşa Köftecisi';
-- Döner: köfte Türk ızgara, döner kategorisine girer.

UPDATE restaurant SET categories = ARRAY['Tatlı', 'Kahve']
    WHERE business_name = 'Çengelköy Çikolatacısı';
-- Tatlı + Kahve: çikolata dükkanları neredeyse her zaman kahve de sunar; Tatlı birincil.

UPDATE restaurant SET categories = ARRAY['Steak', 'Döner']
    WHERE business_name = 'İdealtepe Izgara';
-- Steak + Döner: ızgara restoranı hem biftek (steak) hem kebap/köfte (döner) çıkarır.

UPDATE restaurant SET categories = ARRAY['Makarna']
    WHERE business_name = 'Göztepe Makarna';
-- Makarna: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Sushi']
    WHERE business_name = 'Ataşehir Sushico';
-- Sushi: tereddüt yok.

-- ─────────────────────────────────────────────────────────────────────────────
-- Anadolu Yakası — Yeni konseptler
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE restaurant SET categories = ARRAY['Vegan', 'Salata']
    WHERE business_name = 'Caddebostan Vegan Bistro';
-- Vegan + Salata: vegan bistro hem hayvansal içermeyen hem de salata ağırlıklı menü sunar.

UPDATE restaurant SET categories = ARRAY['Sushi']
    WHERE business_name = 'Suadiye Sushi Master';
-- Sushi: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Salata', 'Tatlı']
    WHERE business_name = 'Moda Kahvaltı Evi';
-- Salata + Tatlı: Türk kahvaltısı = söğüş/domates/salatalık (Salata) + bal/reçel/simit (Tatlı).

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Bağdat Kokoreççisi';
-- Döner: kokoreç Türk sokak yemeği, Döner kategorisi en yakın (et bazlı sandviç).

UPDATE restaurant SET categories = ARRAY['Hamburger']
    WHERE business_name = 'Kadıköy Tacos';
-- Hamburger: Meksika fast food; ayrı kategori yok. Hamburger = fast-food sandviç ailesi.

UPDATE restaurant SET categories = ARRAY['Döner', 'Çorba']
    WHERE business_name = 'Üsküdar Karadeniz Mutfağı';
-- Döner + Çorba: Karadeniz mutfağı = pide/kuymak (Döner) + hamsi çorbası/lahana çorbası (Çorba).

UPDATE restaurant SET categories = ARRAY['Ramen']
    WHERE business_name = 'Ataşehir Wokery';
-- Ramen: Asya wok mutfağı — noodle/ramen bazlı.

UPDATE restaurant SET categories = ARRAY['Kahve', 'Tatlı']
    WHERE business_name = 'Bostancı Kahve Atölyesi';
-- Kahve + Tatlı: specialty coffee atölyesi, yanında pasta/kurabiye standarttır.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Maltepe Tükürük Köftecisi';
-- Döner: köfte = Türk ızgara.

UPDATE restaurant SET categories = ARRAY['Vegan', 'Salata']
    WHERE business_name = 'Erenköy Vegan House';
-- Vegan + Salata: vegan ev = sebze ağırlıklı, salata da önde.

UPDATE restaurant SET categories = ARRAY['Salata', 'Vegan']
    WHERE business_name = 'Caddebostan Salata Bar';
-- Salata + Vegan: salata bar doğası gereği vegan dostu.

UPDATE restaurant SET categories = ARRAY['Döner', 'Tatlı']
    WHERE business_name = 'Kozyatağı Antep Lezzetleri';
-- Döner + Tatlı: Gaziantep mutfağı = kebap/lahmacun (Döner) + baklava/kadayıf (Tatlı).

UPDATE restaurant SET categories = ARRAY['Salata', 'Tatlı']
    WHERE business_name = 'Suadiye Brunch Cafe';
-- Salata + Tatlı: brunch = avokado toast/bowl (Salata) + waffle/pancake (Tatlı).

-- ─────────────────────────────────────────────────────────────────────────────
-- Avrupa Yakası
-- ─────────────────────────────────────────────────────────────────────────────

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Beşiktaş Köftecisi';
-- Döner: köfteci.

UPDATE restaurant SET categories = ARRAY['Pizza']
    WHERE business_name = 'Taksim Pizzeria Roma';
-- Pizza: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Salata', 'Tatlı']
    WHERE business_name = 'Bakırköy Kahvaltı Evi';
-- Salata + Tatlı: kahvaltı tabağı (Moda Kahvaltı Evi ile aynı mantık).

UPDATE restaurant SET categories = ARRAY['Steak', 'Döner']
    WHERE business_name = 'Küçükçekmece Et Mangal';
-- Steak + Döner: et mangal = hem biftek (steak) hem mangal kebabı (döner) çıkarır.

UPDATE restaurant SET categories = ARRAY['Deniz Ürünleri']
    WHERE business_name = 'Florya Sahil Balık';
-- Deniz Ürünleri: sahil balık restoranı.

UPDATE restaurant SET categories = ARRAY['Vegan', 'Salata']
    WHERE business_name = 'Beyoğlu Vegan Lab';
-- Vegan + Salata: vegan laboratuvarı = bitkisel, salata ağırlıklı.

UPDATE restaurant SET categories = ARRAY['Kahve', 'Tatlı']
    WHERE business_name = 'Cihangir Specialty Coffee';
-- Kahve + Tatlı: specialty coffee = esas kahve, yanında mutlaka tatlı.

UPDATE restaurant SET categories = ARRAY['Sushi']
    WHERE business_name = 'Levent Sushi Bar';
-- Sushi: tereddüt yok.

UPDATE restaurant SET categories = ARRAY['Hamburger']
    WHERE business_name = 'Beşiktaş Mexican Cantina';
-- Hamburger: Meksika mutfağı (taco/burrito). Ayrı kategori yok; fast-food sandviç ailesine en yakın.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Etiler Doğu Mutfağı';
-- Döner: Orta Doğu mutfağı = shawarma/kebap ailesi, Döner'e girer.

UPDATE restaurant SET categories = ARRAY['Salata', 'Tatlı']
    WHERE business_name = 'Bebek Brunch & More';
-- Salata + Tatlı: brunch (Suadiye Brunch ile aynı mantık).

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Karaköy Kokoreçhanesi';
-- Döner: kokoreç = Türk sokak yemeği, et bazlı sandviç.

UPDATE restaurant SET categories = ARRAY['Kahve', 'Tatlı']
    WHERE business_name = 'Galata Kahve Sanatı';
-- Kahve + Tatlı: kahve sanatı = specialty coffee + pasta.

UPDATE restaurant SET categories = ARRAY['Döner']
    WHERE business_name = 'Şişli Kebap Sarayı';
-- Döner: kebap sarayı.

UPDATE restaurant SET categories = ARRAY['Tatlı']
    WHERE business_name = 'Beyoğlu Sokak Tatlıcısı';
-- Tatlı: sokak tatlıcısı — dondurma, waffle, gözleme tatlı.

UPDATE restaurant SET categories = ARRAY['Vegan', 'Salata']
    WHERE business_name = 'Yeşilköy Vegan Garden';
-- Vegan + Salata: vegan bahçe.

UPDATE restaurant SET categories = ARRAY['Steak', 'Döner']
    WHERE business_name = 'Bakırköy Anatolian Grill';
-- Steak + Döner: Anadolu ızgarası = hem biftek hem kebap.

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. cuisine_type sütununu birincil kategori ile senkronize et
-- ─────────────────────────────────────────────────────────────────────────────
UPDATE restaurant
    SET cuisine_type = categories[1]
    WHERE array_length(categories, 1) > 0;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Kategorisiz kalan varsa uyar (sıfır satır beklenir)
-- ─────────────────────────────────────────────────────────────────────────────
DO $$
DECLARE uncategorized INT;
BEGIN
    SELECT COUNT(*) INTO uncategorized FROM restaurant WHERE categories = '{}';
    IF uncategorized > 0 THEN
        RAISE WARNING '% restoran kategorisiz kaldı — kontrol gerekli!', uncategorized;
    ELSE
        RAISE NOTICE 'Tüm restoranlar başarıyla kategorilendi.';
    END IF;
END $$;

COMMIT;
