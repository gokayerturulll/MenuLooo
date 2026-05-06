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
    @StateObject private var favouritesManager = FavouritesManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favouritesManager)
        }
    }
}
