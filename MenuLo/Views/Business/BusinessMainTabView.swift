//
//  BusinessMainTabView.swift
//  MenuLo
//
//  MenuLo/Views/Business/BusinessMainTabView.swift
//
//  İşletme sahipleri için 3 sekmeli ana navigasyon: Menü · Dükkanım · Hesap.
//  Tasarım dili müşteri tarafındaki MainTabView ile birebir uyumludur.
//

import SwiftUI

struct BusinessMainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            // Tab 0: Menü Yönetimi — sahip olunan restoranın CRUD paneli
            NavigationStack {
                MenuManagerView(restaurantId: authVM.currentUser?.restaurantId ?? 1)
            }
            .tabItem {
                Label("Menü",
                      systemImage: selectedTab == 0 ? "tray.full.fill" : "tray.full")
            }
            .tag(0)

            // Tab 1: Dükkanım (işletme profili)
            NavigationStack { MyBusinessView() }
                .tabItem {
                    Label("Dükkanım",
                          systemImage: selectedTab == 1 ? "building.2.fill" : "building.2")
                }
                .tag(1)

            // Tab 2: Hesap
            NavigationStack { BusinessAccountView() }
                .tabItem {
                    Label("Hesap",
                          systemImage: selectedTab == 2 ? "person.crop.circle.fill" : "person.crop.circle")
                }
                .tag(2)
        }
        .tint(MenuLoTheme.Colors.primary)
    }
}

// MARK: - Preview
#Preview {
    BusinessMainTabView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.currentUser = User.businessExample
            vm.isAuthenticated = true
            return vm
        }())
}
