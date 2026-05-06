//
//  FavouritesManager.swift
//  MenuLo
//
//  Kullanıcının favoriye aldığı restoranların global state yönetimi.
//

import SwiftUI

class FavouritesManager: ObservableObject {
    @Published var favoriteRestaurantIDs: Set<Int> = []
    
    // Toggle işlemi: Eğer favoriyse çıkarır, değilse ekler.
    func toggleFavorite(restaurantID: Int) {
        if favoriteRestaurantIDs.contains(restaurantID) {
            favoriteRestaurantIDs.remove(restaurantID)
        } else {
            favoriteRestaurantIDs.insert(restaurantID)
        }
    }
    
    // Favori durumu kontrolü
    func isFavorite(restaurantID: Int) -> Bool {
        return favoriteRestaurantIDs.contains(restaurantID)
    }
    
}
