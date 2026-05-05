//
//  ContentView.swift
//  MenuLo
//
//  Uygulamanın kök View'ı — Auth durumuna göre Login veya Ana Ekran gösterir.
//
//  ## Akış Mantığı:
//  ```
//  ContentView
//  ├── isAuthenticated == false → LoginView (Giriş ekranı)
//  └── isAuthenticated == true  → MainTabView (4 sekmeli ana ekran)
//  ```
//
//  ## @EnvironmentObject Nedir?
//  `MenuLoApp.swift`'te `.environmentObject(authViewModel)` ile enjekte edilen
//  nesneye buradan `@EnvironmentObject` ile erişiyoruz. Bu sayede prop drilling
//  (veriyi her View'a tek tek geçirme) yapmadan, View hiyerarşisinin herhangi
//  bir yerinden AuthViewModel'e ulaşabiliriz.
//

import SwiftUI

struct ContentView: View {
    
    /// Üst View'dan (MenuLoApp) enjekte edilen AuthViewModel.
    /// Kullanıcının giriş durumunu dinler ve arayüzü buna göre günceller.
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // ✅ Kullanıcı giriş yapmış → Ana uygulama
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // 🔐 Kullanıcı giriş yapmamış → Giriş ekranı
                LoginView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authViewModel.isAuthenticated)
    }
}

// MARK: - SwiftUI Preview

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
