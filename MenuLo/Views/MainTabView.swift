//
//  MainTabView.swift
//  MenuLo
//
//  Uygulamanın ana Tab Bar navigasyonu.
//  5 sekme: Discover, MenuBot, QR Scan, Favourites, Profile
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // MARK: - Tab 1: Discover (Harita)
            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("Discover", systemImage: selectedTab == 0 ? "map.fill" : "map")
            }
            .tag(0)

            // MARK: - Tab 2: MenuBot (AI Asistan)
            NavigationStack {
                MenuBotView()
            }
            .tabItem {
                Label("MenuBot", systemImage: selectedTab == 1 ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
            }
            .tag(1)

            // MARK: - Tab 3: QR Scan (Kamera)
            NavigationStack {
                QRScanView()
            }
            .tabItem {
                Label("QR Scan", systemImage: "qrcode.viewfinder")
            }
            .tag(2)

            // MARK: - Tab 4: Favourites (Favoriler)
            NavigationStack {
                FavouritesView()
            }
            .tabItem {
                Label("Favourites", systemImage: selectedTab == 3 ? "heart.fill" : "heart")
            }
            .tag(3)

            // MARK: - Tab 5: Profile (Profil)
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
            }
            .tag(4)
        }
        .tint(MenuLoTheme.Colors.primary)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
