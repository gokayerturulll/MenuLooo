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
        // Login sonrası kullanıcı tipine göre yönlendirme:
        // .login          → LoginView
        // .customerHome   → MainTabView (Keşfet açılır)
        // .businessHome   → MenuManagerView paneli
        switch authVM.rootDestination {
        case .login:
            LoginView()
                .environmentObject(authVM)
        case .customerHome:
            MainTabView()
                .environmentObject(authVM)
        case .businessHome:
            BusinessMainTabView()
                .environmentObject(authVM)
        }
    }
}
