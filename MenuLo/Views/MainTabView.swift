//
//  MainTabView.swift
//  MenuLo
//
//  Uygulamanın ana Tab Bar navigasyonu.
//
//  ## SwiftUI TabView Nedir?
//  `TabView`, iOS'taki alt sekme çubuğunu (Tab Bar) oluşturur.
//  Her sekme bir `Tab` veya `.tabItem` ile tanımlanır ve
//  kullanıcı sekmeler arasında dokunarak geçiş yapar.
//
//  ## Yapı:
//  ```
//  TabView
//  ├── Tab 1: 🔍 Keşfet   → DiscoverView
//  ├── Tab 2: 🤝 Odalar   → RoomListView
//  ├── Tab 3: 🤖 MenuBot  → MenuBotView
//  └── Tab 4: 👤 Profil    → ProfileView
//  ```
//

import SwiftUI

struct MainTabView: View {
    
    /// Seçili olan sekmenin indeksi. `@State` ile View'a özel durum yönetimi.
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            // MARK: - Tab 1: Keşfet
            DiscoverView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Keşfet")
                }
                .tag(0)
            
            // MARK: - Tab 2: Odalar
            RoomListView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("Odalar")
                }
                .tag(1)
            
            // MARK: - Tab 3: MenuBot
            MenuBotView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("MenuBot")
                }
                .tag(2)
            
            // MARK: - Tab 4: Profil
            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle.fill")
                    Text("Profil")
                }
                .tag(3)
        }
        .tint(MenuLoTheme.Colors.primary) // Tab bar aktif rengi: #FFA63B
    }
}

// MARK: - SwiftUI Preview

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
