# MenuLo - Proje Kuralları ve Geliştirme Standartları

## 1. Proje Özeti
MenuLo; bilgi asimetrisini çözen, "Green Menu" ile gıda israfını önleyen, ortak grup karar odaları sunan ve AI asistanı barındıran iOS odaklı bir sosyal gastronomi platformudur.

## 2. Teknoloji Yığını (Tech Stack)
- **Frontend (iOS):** Swift, SwiftUI (MVVM Mimarisi).
- **Backend:** Node.js, Express.js.
- **Veritabanı:** PostgreSQL.
- **Yapay Zeka:** Python, NumPy, Pandas (MenuBot ve pazar analizleri için).
- **Gerçek Zamanlı Veri:** Socket.io (Grup odaları ve anlık bildirimler için).

## 3. QR Kod ve Kamera Kullanım Senaryoları
Uygulama içinde kamera (AVFoundation) şu iki kritik görev için kullanılacaktır:
1. **Restoran Menü Erişimi:** Masadaki QR kodu tarayarak doğrudan dijital menüye gitmek (UC05).
2. **Grup Karar Odası:** Bir arkadaşının oluşturduğu QR kodu tarayarak odaya saniyeler içinde katılmak (UC10).

## 4. Kodlama ve Tasarım Standartları
- **Renk:** Ana turuncu `#FFA63B`. Font: `Gabarito`.
- **SwiftUI:** Sadece SwiftUI kullanılacaktır. UIKit köprüleri (UIViewRepresentable) sadece QR okuyucu (AVFoundation) ve Harita (MapKit) için gereklidir.
- **Güvenlik:** PostgreSQL sorguları SQL Injection'a karşı korunmalı, iOS tarafında API anahtarları ve hassas veriler güvenli saklanmalıdır.
- **Hata Yönetimi:** Opsiyonel değişkenler her zaman güvenli bağlanmalı (`guard let`, `if let`), force unwrap (`!`) kullanılmamalıdır.

## 5. AI İletişim Kuralları
- Adımları modüler ve sıfırdan anlatarak ver.
- Her kod bloğunun hangi dosya yoluna ait olduğunu belirt.