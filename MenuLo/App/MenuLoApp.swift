//
//  MenuLoApp.swift
//  MenuLo
//
//  Uygulamanın başlangıç noktası.
//

import SwiftUI

@main
struct MenuLoApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    // MARK: - Single Source of Truth
    @StateObject private var favouritesManager = FavouritesManager.shared
    @StateObject private var discoverVM        = DiscoverViewModel()
    @StateObject private var deepLinkRouter    = DeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favouritesManager)
                .environmentObject(discoverVM)
                .environmentObject(deepLinkRouter)
                .task {
                    await discoverVM.fetchNearbyRestaurants()
                }
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}
