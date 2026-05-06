//
//  MenuLoApp.swift
//  MenuLo
//
//  Uygulamanın başlangıç noktası.
//

import SwiftUI

@main
struct MenuLoApp: App {

    // MARK: - Single Source of Truth
    // Restoran verisi ve favoriler uygulama yaşam döngüsü boyunca tek bir
    // instance üzerinden paylaşılır. Alt sekmeler (Discover/Map/Favourites)
    // bunları @EnvironmentObject ile okur — kendi instance'larını oluşturmaz.
    @StateObject private var favouritesManager = FavouritesManager()
    @StateObject private var discoverVM = DiscoverViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favouritesManager)
                .environmentObject(discoverVM)
                .task {
                    // Tüm uygulama için TEK fetch — fetchNearbyRestaurants
                    // idempotent (cache + isLoading guard) olduğu için
                    // tekrar mount olsa bile tekrar API'ye gitmez.
                    await discoverVM.fetchNearbyRestaurants()
                }
        }
    }
}
