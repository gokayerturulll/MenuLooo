//
//  ContentView.swift
//  MenuLo
//
//  Uygulamanın ana sekme yapısını (Tab Bar) yöneten görünüm.
//

import SwiftUI

struct ContentView: View {
    // Seçili olan sekmeyi takip etmek için @State (durum) değişkeni kullanıyoruz.
    // 0: Keşfet, 1: Harita, 2: QR/Oda, 3: MenuBot, 4: Profil
    @State private var selectedTab: Int = 0
    
    var body: some View {
        // TabView, uygulamanın altındaki sekme çubuğunu oluşturur.
        TabView(selection: $selectedTab) {
            
            // 1. Sekme: Keşfet (Arama ve listeleme)
            Text("Keşfet Görünümü (DiscoverView) Gelecek")
                .tabItem {
                    Label("Keşfet", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            // 2. Sekme: Harita (Yakındaki restoranlar)
            Text("Harita Görünümü (MapView) Gelecek")
                .tabItem {
                    Label("Harita", systemImage: "map.fill")
                }
                .tag(1)
            
            // 3. Sekme: QR/Oda (Karar Odası ve QR Okuyucu)
            Text("QR ve Karar Odası (GroupRoomView) Gelecek")
                .tabItem {
                    Label("QR/Oda", systemImage: "qrcode.viewfinder")
                }
                .tag(2)
            
            // 4. Sekme: MenuBot (AI Asistanı)
            Text("MenuBot Asistanı Gelecek")
                .tabItem {
                    Label("MenuBot", systemImage: "sparkles")
                }
                .tag(3)
            
            // 5. Sekme: Profil (Kullanıcı hesap işlemleri)
            Text("Profil Görünümü (ProfileView) Gelecek")
                .tabItem {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .tag(4)
        }
        // Ana tema rengimiz olan turuncuyu sekme ikonlarına uyguluyoruz
        // (Hex formatındaki extension'ımızı kullanıyoruz)
        .accentColor(Color(hex: "#FFA63B")) 
    }
}

// SwiftUI Canvas'ta (Preview) anlık olarak görmek için kullanılan kod
#Preview {
    ContentView()
}
