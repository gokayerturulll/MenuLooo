//
//  ContentView.swift
//  MenuLo
//
//  MenuLo/Views/ContentView.swift
//
//  Uygulamanın ana sekme yapısını (Tab Bar) yöneten görünüm.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    
    // Uygulama genelinde giriş durumunu (Auth) tutan state (örnek olarak AuthViewModel burada yaratılabilir)
    @StateObject private var authVM = AuthViewModel()
    
    var body: some View {
        // Eğer kullanıcı giriş yapmamışsa (LoginView) gösterilir.
        if !authVM.isAuthenticated {
            LoginView()
                .environmentObject(authVM)
        } else {
            // Giriş yapıldıysa Ana Sekmeler gösterilir.
            TabView(selection: $selectedTab) {
                
                // 1. Sekme: Keşfet
                Text("Keşfet: Liste Arama (Gelecek)")
                    .tabItem {
                        Label("Keşfet", systemImage: "magnifyingglass")
                    }
                    .tag(0)
                
                // 2. Sekme: Harita (Az önce yazdığımız tasarım)
                DiscoverView()
                    .tabItem {
                        Label("Harita", systemImage: "map.fill")
                    }
                    .tag(1)
                
                // 3. Sekme: QR/Oda
                Text("QR ve Karar Odası (GroupRoomView) Gelecek")
                    .tabItem {
                        Label("QR/Oda", systemImage: "qrcode.viewfinder")
                    }
                    .tag(2)
                
                // 4. Sekme: MenuBot
                Text("MenuBot Asistanı Gelecek")
                    .tabItem {
                        Label("MenuBot", systemImage: "sparkles")
                    }
                    .tag(3)
                
                // 5. Sekme: Profil
                Text("Profil Görünümü (ProfileView) Gelecek")
                    .tabItem {
                        Label("Profil", systemImage: "person.crop.circle")
                    }
                    .tag(4)
            }
            .accentColor(MenuLoTheme.Colors.primary) 
            .environmentObject(authVM)
        }
    }
}
