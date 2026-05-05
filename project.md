# 🍏 Menulo: iOS (iPhone) App Specification

> [cite_start]**Proje Özeti:** Restoranlar ve müşteriler arasındaki bilgi asimetrisini ortadan kaldıran [cite: 140][cite_start], gıda israfını önleyen ve yapay zeka destekli öneriler sunan [cite: 142][cite_start], iPhone kullanıcıları için optimize edilmiş dijital menü ve sosyal gastronomi platformu[cite: 140].

---

## 🎨 1. UI/UX Tasarım ve Marka Kimliği (iOS Odaklı)

iOS kullanıcılarının alışkın olduğu akıcı deneyimi sağlamak için tasarım standartları:

* [cite_start]**Ana Renk (Primary Color):** `#FFA63B` [cite: 2388] (Butonlar, aktif sekmeler ve vurgular için).
* [cite_start]**Tipografi:** `Gabarito` [cite: 2389] (Temiz, okunabilir ve modern bir görünüm için).
* **Navigasyon:** Uygulama alt barı (Tab Bar) ve ekranlar arası geçişler (Navigation Stack) Apple standartlarına uygun tasarlanmalıdır.
* [cite_start]**Ekran Akışları:** * Açılış (Splash) -> Giriş/Kayıt[cite: 2391].
    * [cite_start]Keşfet (Harita) -> Restoran Detayı -> Menü[cite: 2392].
    * [cite_start]Oda Lobisi -> Oda Oluşturma -> Arkadaş Etkileşimi[cite: 2393].
    * [cite_start]MenuBot -> Chatbot Etkileşimleri[cite: 2394].

---

## 🏗️ 2. Teknoloji Yığını (Tech Stack)

### 📱 Frontend (iOS Client)
* **Çerçeve:** React Native (Expo) **VEYA** Swift (SwiftUI).
* [cite_start]**Donanım Erişimleri:** * QR okuma işlemleri için cihaz kamerası entegrasyonu (örn. `expo-camera` veya `AVFoundation`)[cite: 2638].
    * [cite_start]Konum tabanlı hizmetler için GPS entegrasyonu (örn. `expo-location` veya `CoreLocation`)[cite: 1438].
* **Durum Yönetimi (State Management):** Redux Toolkit veya Zustand (Kullanıcı seansları, favoriler ve sepet yönetimi için).

### ⚙️ Backend & Servisler
* **Sunucu:** Node.js, Express.js.
* **Veritabanı:** MySQL (İlişkisel veriler, menü hiyerarşisi ve kullanıcı profilleri için).
* **Gerçek Zamanlı İletişim:** Socket.io (Grup Karar Odaları ve anlık Yeşil Menü bildirimleri için).

### 🧠 Veri Bilimi ve Yapay Zeka (MenuBot)
* **Dil ve Kütüphaneler:** Python, NumPy, Pandas (Veri işleme, analiz ve makine öğrenimi modelleri için).
* [cite_start]**Görev:** Kullanıcının geçmiş aramaları, bütçesi ve konumu üzerinden anlık restoran/menü önerisi (MenuBot) üretmek[cite: 2650]. [cite_start]Pazar analitiği raporlamalarını (DaaS) beslemek[cite: 2637, 2653].

---

## 🚀 3. Temel Özellikler (Core Epics) & iOS Entegrasyonları

### 📍 Epik 1: Keşif ve Konum Bazlı Arama
* [cite_start]**Harita Entegrasyonu:** Apple Maps veya Google Maps API üzerinden kullanıcının anlık konumunun alınması ve çevredeki restoranların harita üzerinde pinlerle (Map Result Visualization) gösterilmesi[cite: 1328, 1330].
* [cite_start]**Granüler Arama:** Kullanıcıların spesifik yemek (örn. Cheeseburger) [cite: 83, 107] [cite_start]veya bütçe aralığı [cite: 1422] girmesine olanak tanıyan hızlı arama çubuğu.
* [cite_start]**QR Erişim:** iPhone kamerasını kullanarak masadaki QR kodların taranması ve menüye doğrudan, saniyeler içinde erişim (QR Code Menu Access)[cite: 1471, 1473].

### 🌱 Epik 2: Yeşil Menü (Sürdürülebilirlik)
* [cite_start]**Push Bildirimleri (APNs):** Gün sonu yaklaşan işletmelerin gıda israfını önlemek için [cite: 2651] [cite_start]yayınladığı indirimli "Yeşil Menü" fırsatlarının, yakındaki kullanıcılara kilit ekranı bildirimi olarak iletilmesi[cite: 1551, 1553].
* [cite_start]**Otomatik Süre (Auto Timer):** İşletmelerin belirlediği son kullanma süresinin dolmasıyla ürünlerin iOS uygulamasından anında (gerçek zamanlı) kaldırılması[cite: 1607, 1608].

### 🤝 Epik 3: Yapay Zeka (MenuBot) & Sosyal Karar
* **MenuBot Chat UI:** Apple'ın iMessage arayüzüne benzer, akıcı bir sohbet deneyimi sunan AI asistanı. [cite_start]Bütçe ve lokasyona göre kişiselleştirilmiş menü tavsiyeleri verir[cite: 547].
* **Grup Karar Odası:** Arkadaş gruplarının QR kod taratarak veya iMessage üzerinden davet linkiyle katılabileceği canlı karar odaları. [cite_start]Ortak diyet ve bütçe filtreleri analiz edilerek (Match Collective Results) [cite: 1650, 1652] en uygun mekanın önerilmesi.

### 🛡️ Epik 4: Yönetim ve Güvenlik
* **FaceID/TouchID Entegrasyonu:** İşletme sahipleri ve kullanıcılar için biyometrik güvenlikle hızlı oturum açma.
* [cite_start]**Uçtan Uca Şifreleme:** Kullanıcı verileri [cite: 2147][cite_start], restoran verileri [cite: 2148] [cite_start]ve şifrelerin (en az 256-bit) [cite: 2149] güvenli bir şekilde saklanması. (iOS Keychain kullanımı önerilir).
* [cite_start]**İçerik Moderasyonu:** İşletmelerin yüklediği görsellerin yapay zeka ile otomatik analiz edilmesi ve uygunsuz içeriklerin (Image Analysis) engellenmesi[cite: 1800, 1802].

---

## 📏 4. Performans ve Kalite Metrikleri (NFRs)

Uygulamanın App Store onay süreçlerinden sorunsuz geçebilmesi için kritik performans hedefleri:

* [cite_start]**⚡ Yanıt Süresi:** Arama ve filtreleme işlemleri yoğun yük altında (1000 eşzamanlı kullanıcı) [cite: 2157] [cite_start]dahi maksimum **2 saniye** içinde sonuç vermelidir[cite: 2140].
* **🔋 Pil ve Kaynak Tüketimi:** Arka planda çalışan GPS ve Socket bağlantılarının iPhone bataryasını tüketmemesi için optimize edilmesi. [cite_start]Sadece uygulama aktifken veya kullanıcının açık rızası alındığında [cite: 2169] konum verisi işlenmelidir.
* [cite_start]**🛠️ Bakım ve Güncelleme:** Modüler mimari (Independent Updates) [cite: 2016, 2018] [cite_start]kullanılarak uygulamanın belirli bileşenlerinin tüm sistemi etkilemeden güncellenebilmesi[cite: 2162].