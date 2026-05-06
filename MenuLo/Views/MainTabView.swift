//
//  MainTabView.swift
//  MenuLo
//
//  Ana Tab Bar navigasyonu — 5 sekme + Floating Action Button (MenuBot).
//  Sekmeler: Keşfet · Harita · QR/Oda · Favoriler · Profil
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0
    @State private var showMenuBot = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Tab View
            TabView(selection: $selectedTab) {

                // Tab 0: Keşfet
                NavigationStack { DiscoverView() }
                    .tabItem { Label("Keşfet", systemImage: selectedTab == 0 ? "magnifyingglass.circle.fill" : "magnifyingglass") }
                    .tag(0)

                // Tab 1: Harita
                NavigationStack { MapView() }   // Harita tab'ı — DiscoverView harita odaklı
                    .tabItem { Label("Harita", systemImage: selectedTab == 1 ? "map.fill" : "map") }
                    .tag(1)

                // Tab 2: QR / Grup Karar Odası
                NavigationStack { QRScanView() }
                    .tabItem { Label("Oda", systemImage: selectedTab == 2 ? "qrcode.viewfinder" : "qrcode") }
                    .tag(2)

                // Tab 3: Favoriler
                NavigationStack { FavouritesView() }
                    .tabItem { Label("Favoriler", systemImage: selectedTab == 3 ? "heart.fill" : "heart") }
                    .tag(3)

                // Tab 4: Profil
                NavigationStack { ProfileView() }
                    .tabItem { Label("Profil", systemImage: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle") }
                    .tag(4)
            }
            .tint(MenuLoTheme.Colors.primary)

            // MARK: - Floating Action Button (MenuBot)
            HStack {
                Spacer()
                Button {
                    showMenuBot = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.55), radius: 14, x: 0, y: 6)

                        Image(systemName: "sparkles")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, MenuLoTheme.Spacing.lg)
                .padding(.bottom, 120) // TabBar ve harita butonlarının üzerine çıkması için boşluk artırıldı
                .fullScreenCover(isPresented: $showMenuBot) {
                    MenuBotView()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
