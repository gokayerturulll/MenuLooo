//
//  PreviewHelpers.swift
//  MenuLo
//
//  DEBUG-only yardımcılar. Xcode Preview canvas'ında ağ isteği olmadan
//  gerçekçi örnek veriyle view'ları göstermek için kullanılır.
//

#if DEBUG
import Foundation

// MARK: - Restaurant Sample Data

extension Restaurant {
    static var previewData: [Restaurant] {
        [
            Restaurant(
                restaurantId: 1, ownerId: 1,
                businessName: "Moda Burger",
                address: "Moda Cad. No: 12, Kadıköy",
                latitude: 40.9852, longitude: 29.0251,
                avgRating: 4.5, reviewCount: 120,
                priceRange: "₺₺", cuisineType: "Burger",
                categories: ["Hamburger"],
                distanceM: 350, isOpenNow: true
            ),
            Restaurant(
                restaurantId: 2, ownerId: 2,
                businessName: "Ataşehir Kebap",
                address: "Kayışdağı Mah. Uslu Sok., Ataşehir",
                latitude: 40.9785, longitude: 29.1411,
                avgRating: 4.2, reviewCount: 89,
                priceRange: "₺", cuisineType: "Kebap",
                categories: ["Döner"],
                distanceM: 1200, isOpenNow: true
            ),
            Restaurant(
                restaurantId: 3, ownerId: 3,
                businessName: "Kalamış Brasserie",
                address: "Fenerbahçe Mah. Kalamış Fener Cad., Kadıköy",
                latitude: 40.9745, longitude: 29.0398,
                avgRating: 4.8, reviewCount: 234,
                priceRange: "₺₺₺", cuisineType: "Akdeniz",
                categories: ["Steak", "Makarna", "Salata"],
                distanceM: 800, isOpenNow: false
            ),
            Restaurant(
                restaurantId: 4, ownerId: 4,
                businessName: "Kozyatağı Pizzeria",
                address: "Kozyatağı Mah. Bayar Cad., Kadıköy",
                latitude: 40.9732, longitude: 29.0965,
                avgRating: 4.1, reviewCount: 67,
                priceRange: "₺₺", cuisineType: "Pizza",
                categories: ["Pizza"],
                distanceM: 2100, isOpenNow: true
            ),
            Restaurant(
                restaurantId: 5, ownerId: 2,
                businessName: "Ataşehir Sushico",
                address: "Atatürk Mah. Ataşehir Bulvarı, Ataşehir",
                latitude: 40.9912, longitude: 29.1213,
                avgRating: 4.6, reviewCount: 180,
                priceRange: "₺₺₺", cuisineType: "Sushi",
                categories: ["Sushi"],
                distanceM: 3500, isOpenNow: true
            ),
        ]
    }
}

// MARK: - DiscoverViewModel Preview Factory

extension DiscoverViewModel {
    /// Ağ isteği yapmadan örnek restoranlarla dolu bir DiscoverViewModel döner.
    /// Yalnızca #Preview bloklarında kullanın.
    static func preview() -> DiscoverViewModel {
        let vm = DiscoverViewModel()
        vm.restaurants = Restaurant.previewData
        return vm
    }
}
#endif
