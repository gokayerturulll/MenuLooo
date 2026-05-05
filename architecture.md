# MenuLo - Klasör Yapısı ve Mimari

📁 MenuLo-iOS
 ├── 📁 App (Giriş noktası)
 ├── 📁 Models (User, Restaurant, Menu, GroupRoom)
 ├── 📁 Views
 │    ├── 📁 Auth (Giriş/Kayıt)
 │    ├── 📁 Discover (Harita ve Arama)
 │    ├── 📁 Menu (Kategoriler ve Ürünler)
 │    ├── 📁 GroupRoom (QR tarama ve Karar odası)
 │    └── 📁 Components (Reusable UI)
 ├── 📁 ViewModels (Mantık ve Durum Yönetimi)
 ├── 📁 Services
 │    ├── NetworkManager.swift (API)
 │    ├── LocationManager.swift (GPS)
 │    ├── CameraManager.swift (QR Okuma - AVFoundation)
 │    └── SocketManager.swift (Canlı Oda)
 └── Info.plist (Kamera ve Konum İzinleri)