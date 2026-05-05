//
//  MenuLoApp.swift
//  MenuLo
//
//  Uygulamanın giriş noktası (@main).
//
//  ## @main Nedir?
//  Swift'te `@main` attribute'u, uygulamanın başlangıç noktasını belirler.
//  iOS'ta bu, `App` protokolünü benimseyen bir struct'tır.
//  Uygulama başlatıldığında ilk olarak bu dosyadaki `body` çalışır.
//
//  ## @StateObject vs @ObservedObject
//  - `@StateObject`: Nesneyi OLUŞTURUR ve sahiplenir. Yaşam döngüsünü yönetir.
//    View yeniden çizilse bile nesne yeniden oluşturulmaz.
//  - `@ObservedObject`: Dışarıdan gelen nesneyi DİNLER. Sahiplik almaz.
//
//  AuthViewModel burada `@StateObject` olarak oluşturulur çünkü
//  bu nesnenin yaşam döngüsü uygulamanın kendisiyle eşdeğerdir.
//

import SwiftUI

@main
struct MenuLoApp: App {
    
    /// Kimlik doğrulama ViewModel'i — uygulama boyunca tek bir instance (singleton-benzeri).
    /// `@StateObject` ile burada oluşturulur ve `.environmentObject()` ile
    /// tüm alt View'lara enjekte edilir.
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
