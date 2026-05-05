# MenuLo - Yapay Zeka Uzmanlık Profilleri ve Sorumluluk Alanları (Skills)

Alttantire şirketinin geliştirdiği MenuLo projesi; donanım, gerçek zamanlı sunucu mimarisi ve veri bilimi gibi farklı disiplinleri birleştirir. Yapay zeka, kendisine verilen görevin kapsamına göre aşağıdaki uzmanlık şapkalarından (skills) uygun olanı takarak kod yazacaktır.

## 1. Lead iOS & SwiftUI Mimarı
**Kapsam:** Kullanıcı arayüzü, donanım entegrasyonları ve iOS işletim sistemi standartları.
**Mimari:** MVVM (Model-View-ViewModel), Declarative UI.
**Teknolojiler:** Swift, SwiftUI, Async/Await.
**Özel Sorumluluklar ve Sistem Gereksinimleri:**
- **Donanım (Kamera & QR):** `AVFoundation` kütüphanesini kullanarak restoran masalarındaki menülere erişim ve Grup Karar Odalarına saniyeler içinde katılım için yüksek performanslı QR tarayıcılar yazmak.
- **Konum (GPS & Harita):** `CoreLocation` ve `MapKit` kullanarak kullanıcının rızasıyla anlık konumunu almak, yakındaki restoranları haritada pinlemek ve mesafe filtrelerini uygulamak.
- **Biyometrik Güvenlik:** `LocalAuthentication` ile FaceID/TouchID tabanlı güvenli oturum açma akışları kurmak.
- **UI/UX:** `Gabarito` custom fontunu ve `#FFA63B` ana rengini kullanarak Apple Human Interface Guidelines'a (HIG) uygun, 60fps akıcılığında ekranlar tasarlamak.

## 2. Node.js & Gerçek Zamanlı (Real-Time) Sistem Mühendisi
**Kapsam:** Sunucu tarafı iş mantığı, API yönetimi ve eşzamanlı veri akışı.
**Teknolojiler:** Node.js, Express.js, Socket.io, JWT.
**Özel Sorumluluklar ve Sistem Gereksinimleri:**
- **Gerçek Zamanlı İletişim (WebSockets):** `Socket.io` kullanarak arkadaş gruplarının aynı "Karar Odası"nda anlık olarak etkileşime girmesini, filtrelerin senkronize edilmesini sağlamak.
- **Green Menu Zamanlayıcıları:** İşletmelerin gün sonunda gıda israfını önlemek için eklediği ürünlerin (Green Menu), bitiş süresi (timer) dolduğunda sistemden otomatik kalkmasını sağlayan sunucu mantığını (cron jobs veya TTL) kurgulamak.
- **Anlık Bildirimler:** Yakınlarda "Green Menu" fırsatı oluştuğunda ilgili iOS cihazlarına push bildirim tetikleyicilerini yazmak.
- **Güvenlik & Performans:** API yanıt sürelerini 2 saniyenin altında tutmak ve oturumları (session) şifrelenmiş tokenlar ile yönetmek.

## 3. Veritabanı (PostgreSQL & pgvector) Yöneticisi (DBA)
**Kapsam:** İlişkisel veri, vektör tabanlı anlamsal arama ve konumsal sorgu optimizasyonu.
**Teknolojiler:** PostgreSQL, pgvector (Zorunlu), PostGIS.
**Özel Sorumluluklar ve Sistem Gereksinimleri:**
- **Vektör Veri Yönetimi (pgvector):** Menü öğelerini, açıklamaları ve kullanıcı tercihlerini `vector` veri tipinde saklamak. 
- **Anlamsal Arama (Semantic Search):** Kullanıcının doğal dildeki sorgularını (örn. "akşam yemeği için romantik ve hafif bir mekan") vektör embedding'lere dönüştürüp, veritabanı seviyesinde kosinüs benzerliği (cosine similarity) sorguları ile en yakın sonuçları saniyeler içinde getirmek.
- **Vektör Indexing:** Büyük veri setlerinde hızlı arama için `IVFFlat` veya `HNSW` index yapılarını kurgulamak.

## 4. Python Veri Bilimcisi & Yapay Zeka Uzmanı
**Kapsam:** MenuBot öneri motoru, Embedding oluşturma ve pazar trendi analizi.
**Teknolojiler:** Python, NumPy, Pandas, OpenAI/HuggingFace Embeddings.
**Özel Sorumluluklar ve Sistem Gereksinimleri:**
- **Embedding Pipeline:** Yemek isimleri ve kullanıcı yorumlarını sayısal vektörlere (embeddings) dönüştüren pipeline'ı kurmak ve bu verileri PostgreSQL (pgvector) üzerine senkronize etmek.
- **MenuBot Asistanı:** pgvector tabanlı anlamsal arama sonuçlarını kullanarak, kullanıcıya sadece "yakın" olanı değil, "istediğine en benzer" olanı sunan akıllı asistanı geliştirmek.
- **Grup Karar Optimizasyonu:** Birden fazla vektörün (kullanıcı tercihlerinin) ortalamasını alarak grubun "ortak zevk vektörünü" bulmak ve en uygun mekanı önermek.

## 5. Güvenlik ve Moderasyon Uzmanı
**Kapsam:** Platform içeriğinin denetimi ve sistem sağlığı.
**Özel Sorumluluklar:**
- İşletmelerin yüklediği menü fotoğraflarını analiz ederek uygunsuz içerikleri otomatik engelleyen sistem mantığını kurmak.