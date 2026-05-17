//
//  FavouritesManager.swift
//  MenuLo
//
//  Kullanıcının favoriye aldığı restoranların global state yönetimi.
//  UserDefaults ile cihaz üzerinde persiste edilir; uygulama kapansa bile
//  favori listesi korunur.
//

import Foundation

final class FavouritesManager: ObservableObject {

    private let udKey = "menulo_favourite_ids"

    @Published private(set) var favouriteIds: Set<Int> {
        didSet { persist() }
    }

    static let shared = FavouritesManager()

    private init() {
        let saved = UserDefaults.standard.array(forKey: "menulo_favourite_ids") as? [Int] ?? []
        self.favouriteIds = Set(saved)
    }

    func toggle(_ restaurantId: Int) {
        if favouriteIds.contains(restaurantId) {
            favouriteIds.remove(restaurantId)
        } else {
            favouriteIds.insert(restaurantId)
        }
    }

    /// FavouritesView swipe-to-delete için. Var değilse no-op.
    func remove(_ restaurantId: Int) {
        favouriteIds.remove(restaurantId)
    }

    func isFavourite(_ restaurantId: Int) -> Bool {
        favouriteIds.contains(restaurantId)
    }

    private func persist() {
        UserDefaults.standard.set(Array(favouriteIds), forKey: udKey)
    }
}
