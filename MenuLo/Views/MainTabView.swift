import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Int = 0
    @State private var showMenuBot      = false

    // Tüm odalı sekmelerin paylaşacağı tek ViewModel instance
    @StateObject private var roomViewModel = RoomViewModel()

    // Arka plan / ön plan geçişlerini yakalamak için
    @Environment(\.scenePhase) private var scenePhase

    // Deep link yönlendirme
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @EnvironmentObject private var discoverVM:     DiscoverViewModel

    // Deep link ile açılacak restoran detay ekranı
    @State private var deepLinkRestaurant: Restaurant?

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: - Tab View
            TabView(selection: $selectedTab) {

                // Tab 0: Keşfet
                NavigationStack { DiscoverView() }
                    .tabItem { Label("Keşfet", systemImage: selectedTab == 0 ? "magnifyingglass.circle.fill" : "magnifyingglass") }
                    .tag(0)

                // Tab 1: Harita
                MapView()
                    .tabItem { Label("Harita", systemImage: selectedTab == 1 ? "map.fill" : "map") }
                    .tag(1)

                // Tab 2: Grup Karar Odası
                NavigationStack { RoomListView() }
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
            // RoomViewModel tüm tab'larda erişilebilir olsun
            .environmentObject(roomViewModel)

            // MARK: - Floating Action Button (MenuBot) — sadece Keşfet ve Harita sekmelerinde
            if selectedTab == 0 || selectedTab == 1 {
                HStack {
                    Spacer()
                    Button {
                        showMenuBot = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
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
                    .padding(.bottom, 120)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showMenuBot) {
            MenuBotView(restaurantId: nil)
        }
        // MARK: - Bildirim İzni
        .onAppear {
            NotificationManager.shared.requestPermission()
        }
        // MARK: - Deep Link: Restoran Detayı
        .sheet(item: $deepLinkRestaurant) { restaurant in
            NavigationStack {
                RestaurantDetailView(restaurant: restaurant)
            }
        }
        // MARK: - Deep Link: Restoran listesi yüklenince bekleyen deep link'i çöz
        .onChange(of: discoverVM.restaurants) { restaurants in
            guard case .restaurant(let id) = deepLinkRouter.pending,
                  let found = restaurants.first(where: { $0.restaurantId == id }) else { return }
            deepLinkRestaurant = found
            deepLinkRouter.pending = nil
        }
        // MARK: - Deep Link: Yönlendirme
        .onChange(of: deepLinkRouter.pending) { destination in
            guard let destination else { return }
            switch destination {
            case .room:
                selectedTab = 2
                // RoomListView pending'i okuyup odaya katılmayı kendisi yönetir
            case .restaurant(let id):
                selectedTab = 0
                if let found = discoverVM.restaurants.first(where: { $0.restaurantId == id }) {
                    deepLinkRestaurant = found
                    deepLinkRouter.pending = nil
                }
                // Bulunamazsa discoverVM.restaurants yüklenince yukarıdaki onChange devreye girer
            }
        }
        // MARK: - Socket Yaşam Döngüsü
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background:
                // Pil ve ağ tasarrufu: arka planda soketi kapat
                roomViewModel.appDidEnterBackground()
            case .active:
                // Ön plana dönünce — kullanıcı bir odadaysa otomatik yeniden bağlan
                roomViewModel.appDidBecomeActive()
            default:
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(DiscoverViewModel())
        .environmentObject(DeepLinkRouter())
        .environmentObject(FavouritesManager.shared)
}
