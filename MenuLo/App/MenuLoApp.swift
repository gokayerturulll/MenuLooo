//
//  MenuLoApp.swift
//  MenuLo
//
//  Uygulamanın başlangıç noktası.
//

import SwiftUI

@main
struct MenuLoApp: App {
    
    // Uygulama genelinde kullanılacak state veya servis yöneticilerini 
    // ileride buraya tanımlayıp .environmentObject ile alt görünümlere aktaracağız.
    
    var body: some Scene {
        WindowGroup {
            // Uygulama açıldığında kullanıcıyı karşılayacak olan ilk görünüm
            ContentView()
        }
    }
}
