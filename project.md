# 🍏 Menulo: iOS (iPhone) App Specification

> **Proje Özeti:** Restoranlar ve müşteriler arasındaki bilgi asimetrisini ortadan kaldıran, gıda israfını önleyen ve yapay zeka destekli öneriler sunan, iPhone kullanıcıları için optimize edilmiş dijital menü ve sosyal gastronomi platformu.

---

## 🎨 1. UI/UX Tasarım ve Marka Kimliği (iOS Odaklı)

iOS kullanıcılarının alışkın olduğu akıcı deneyimi sağlamak için tasarım standartları:

* **Ana Renk (Primary Color):** `#FFA63B` (Butonlar, aktif sekmeler ve vurgular için).
* **Tipografi:** `Gabarito` (Temiz, okunabilir ve modern bir görünüm için).
* **Navigasyon:** Uygulama alt barı (Tab Bar) ve ekranlar arası geçişler (Navigation Stack) Apple standartlarına uygun tasarlanmalıdır. Alt navigasyon barı 5 ana sekmeden oluşmalıdır: Discover, MenuBot, QR Scan, Favourites ve Profile.
* **Ekran Akışları:** * **Açılış ve Kimlik Doğrulama:** Açılış (Splash) -> Giriş/Kayıt. (Kayıt ekranı "Customer" ve "Business" olmak üzere iki ayrı sekmeden oluşmalıdır).
    * **Müşteri Akışı:** Keşfet (Harita) -> Restoran Detayı -> Menü.
    * **İşletme Sahibi Akışı:** Menu Manager (Menü ekleme/güncelleme) ve My Business (İşletme adı, açıklama, çalışma saatleri düzenleme) panelleri.
    * **Sosyal ve Yapay Zeka Akışı:** Oda Lobisi -> Oda Oluşturma -> Arkadaş Etkileşimi / MenuBot -> Chatbot Etkileşimleri.

---

## 🏗️ 2. Teknoloji Yığını (Tech Stack)

### 📱 Frontend (iOS Client)
* **Çerçeve:** React Native (Expo) **VEYA** Swift (SwiftUI).
* **Donanım Erişimleri:** * QR okuma işlemleri için cihaz kamerası entegrasyonu (örn. `expo-camera` veya `AVFoundation`).
    * Konum tabanlı hizmetler için GPS entegrasyonu (örn. `expo-location` veya `CoreLocation`).
* **Durum Yönetimi (State Management):** Redux Toolkit veya Zustand (Kullanıcı seansları, favoriler ve sepet yönetimi için).

### ⚙️ Backend & Servisler
* **Sunucu:** Node.js, Express.js.
* **Veritabanı:** MySQL (İlişkisel veriler, menü hiyerarşisi ve kullanıcı profilleri için).
* **Gerçek Zamanlı İletişim:** Socket.io (Grup Karar Odaları ve anlık Yeşil Menü bildirimleri için).

### 🧠 Veri Bilimi ve Yapay Zeka (MenuBot)
* **Dil ve Kütüphaneler:** Python, NumPy, Pandas (Veri işleme, analiz ve makine öğrenimi modelleri için).
* **Görev:** Kullanıcının geçmiş aramaları, bütçesi ve konumu üzerinden anlık restoran/menü önerisi (MenuBot) üretmek. Pazar analitiği raporlamalarını (DaaS) beslemek.

---

## 🚀 3. Temel Özellikler (Core Epics) & iOS Entegrasyonları

### 📍 Epik 1: Keşif ve Konum Bazlı Arama
* **Harita Entegrasyonu:** Apple Maps veya Google Maps API üzerinden kullanıcının anlık konumunun alınması ve çevredeki restoranların harita üzerinde pinlerle (Map Result Visualization) gösterilmesi.
* **Granüler Arama ve Filtreleme:** Kullanıcıların spesifik yemek (örn. Cheeseburger) veya bütçe aralığı girmesine olanak tanıyan hızlı arama çubuğu. Çekmece menüsünde "Vegan", "Glütensiz" gibi diyet etiketleri, "Şu an açık", "Evcil Hayvan Dostu" gibi işletme özellikleri ve bir mesafe yarıçapı filtresi bulunmalıdır. Ayrıca sonuçlar fiyat, puan ve en iyi eşleşmeye göre sıralanabilmelidir.
* **QR Erişim:** iPhone kamerasını kullanarak masadaki QR kodların taranması ve menüye doğrudan, saniyeler içinde erişim (QR Code Menu Access).

### 🌱 Epik 2: Yeşil Menü (Sürdürülebilirlik)
* **Push Bildirimleri (APNs):** Gün sonu yaklaşan işletmelerin gıda israfını önlemek için yayınladığı indirimli "Yeşil Menü" fırsatlarının, yakındaki kullanıcılara kilit ekranı bildirimi olarak iletilmesi.
* **Gelişmiş Veri Girişi ve Otomatik Süre (Auto Timer):** İşletme sahibinin yeşil menü ürünü eklerken "Ürün Adı", "Miktar" ve "Açıklama" bilgilerini girmesini sağlayan UI alanları. İşletmelerin belirlediği son kullanma süresinin dolmasıyla ürünlerin iOS uygulamasından anında (gerçek zamanlı) kaldırılması.

### 🤝 Epik 3: Yapay Zeka (MenuBot) & Sosyal Karar
* **MenuBot Chat UI:** Apple'ın iMessage arayüzüne benzer, akıcı bir sohbet deneyimi sunan AI asistanı. Bütçe ve lokasyona göre kişiselleştirilmiş menü tavsiyeleri verir.
* **Grup Karar Odası:** Arkadaş gruplarının QR kod taratarak veya iMessage üzerinden davet linkiyle katılabileceği canlı karar odaları. Ortak diyet ve bütçe filtreleri analiz edilerek (Match Collective Results) en uygun mekanın önerilmesi. Karar odası ekranında "Pizza", "Hamburger" gibi ürün butonları ve "Maksimum Mesafe (km)" kaydırıcısı (slider) bulunmalıdır.

### ⭐ Epik 4: Kullanıcı Etkileşimi (Favoriler ve Değerlendirmeler)
* **Favoriler Modülü (Manage Favorites):** Kullanıcıların beğendikleri restoranları ve menü ürünlerini kalp ikonuyla favorileyebileceği ve bu listeyi "Low to High" gibi seçeneklerle sıralayabileceği özel bir Favourites ekranı.
* **Değerlendirme ve Puanlama (Review and Rating):** Kullanıcıların "Meal Reviews" ve "Restaurant Reviews" sekmeleri altında 5 yıldızlı puanlama yapabileceği ve yorum bırakabileceği, işletme sahiplerinin ise bu yorumlara yanıt dönebileceği arayüz mekanizmaları.

### 🛡️ Epik 5: Yönetim ve Güvenlik
* **FaceID/TouchID Entegrasyonu:** İşletme sahipleri ve kullanıcılar için biyometrik güvenlikle hızlı oturum açma.
* **Uçtan Uca Şifreleme:** Kullanıcı verileri, restoran verileri ve şifrelerin (en az 256-bit) güvenli bir şekilde saklanması. (iOS Keychain kullanımı önerilir).
* **İçerik Moderasyonu:** İşletmelerin yüklediği görsellerin yapay zeka ile otomatik analiz edilmesi ve uygunsuz içeriklerin (Image Analysis) engellenmesi.

---

## 📏 4. Performans ve Kalite Metrikleri (NFRs)

Uygulamanın App Store onay süreçlerinden sorunsuz geçebilmesi için kritik performans hedefleri:

* **⚡ Yanıt Süresi:** Arama ve filtreleme işlemleri yoğun yük altında (1000 eşzamanlı kullanıcı) dahi maksimum **2 saniye** içinde sonuç vermelidir.
* **🔋 Pil ve Kaynak Tüketimi:** Arka planda çalışan GPS ve Socket bağlantılarının iPhone bataryasını tüketmemesi için optimize edilmesi. Sadece uygulama aktifken veya kullanıcının açık rızası alındığında konum verisi işlenmelidir.
* **🛠️ Bakım ve Güncelleme:** Modüler mimari (Independent Updates) kullanılarak uygulamanın belirli bileşenlerinin tüm sistemi etkilemeden güncellenebilmesi.