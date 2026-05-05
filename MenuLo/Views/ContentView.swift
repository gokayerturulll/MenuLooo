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
            MainTabView()
            .environmentObject(authVM)
        }
    }
}
