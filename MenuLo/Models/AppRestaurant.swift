//
//  AppRestaurant.swift
//  MenuLo
//
//  Uygulama genelinde kullanılan restoran modeli ve mock verisi.
//

import SwiftUI

struct AppRestaurant: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let rating: Double
    let reviewCount: Int
    let distance: String
    let priceRange: String
    let tags: [String]
    let emoji: String
    let isOpen: Bool
    let deliveryTime: String
}

struct MockData {
    static let restaurants: [AppRestaurant] = [
        AppRestaurant(name: "Gusto Pizzeria",      cuisine: "İtalyan",    rating: 4.8, reviewCount: 312, distance: "0.4 km", priceRange: "₺₺",  tags: ["Pizza", "Vegan Option"],      emoji: "🍕", isOpen: true,  deliveryTime: "20–30 dk"),
        AppRestaurant(name: "Kadıköy Burger House",cuisine: "Amerikan",   rating: 4.7, reviewCount: 198, distance: "0.7 km", priceRange: "₺",    tags: ["Burger", "Pet Friendly"],     emoji: "🍔", isOpen: true,  deliveryTime: "15–25 dk"),
        AppRestaurant(name: "Green Bowl",          cuisine: "Vegan",      rating: 4.6, reviewCount: 241, distance: "0.9 km", priceRange: "₺₺",  tags: ["Vegan", "Gluten Free"],       emoji: "🥗", isOpen: true,  deliveryTime: "25–35 dk"),
        AppRestaurant(name: "Ramen House Tokyo",   cuisine: "Japon",      rating: 4.5, reviewCount: 175, distance: "1.1 km", priceRange: "₺₺",  tags: ["Ramen", "Sushi"],             emoji: "🍜", isOpen: false, deliveryTime: "30–40 dk"),
        AppRestaurant(name: "Pastane 1888",        cuisine: "Pastane",    rating: 4.9, reviewCount: 523, distance: "0.3 km", priceRange: "₺",    tags: ["Tatlı", "Kahve"],             emoji: "🍰", isOpen: true,  deliveryTime: "10–15 dk"),
        AppRestaurant(name: "Deniz Lokantası",     cuisine: "Türk/Deniz", rating: 4.6, reviewCount: 289, distance: "1.5 km", priceRange: "₺₺₺", tags: ["Seafood", "Halal"],           emoji: "🦐", isOpen: true,  deliveryTime: "35–50 dk"),
        AppRestaurant(name: "Sushi Boshi",         cuisine: "Japon",      rating: 4.4, reviewCount: 132, distance: "2.0 km", priceRange: "₺₺₺", tags: ["Sushi", "Vegetarian Option"], emoji: "🍣", isOpen: true,  deliveryTime: "40–50 dk"),
        AppRestaurant(name: "Kahve Durağı",        cuisine: "Kafe",       rating: 4.7, reviewCount: 410, distance: "0.2 km", priceRange: "₺",    tags: ["Kahve", "Tatlı"],             emoji: "☕️", isOpen: true,  deliveryTime: "5–10 dk"),
    ]
}
