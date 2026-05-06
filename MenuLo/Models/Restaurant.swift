import Foundation
import CoreLocation

struct RestaurantResponse: Codable {
    let success: Bool
    let count: Int?
    let data: [Restaurant]
}

struct Restaurant: Codable, Identifiable {
    let restaurantId: Int
    let ownerId: Int
    let businessName: String
    let address: String?
    
    var id: Int { restaurantId }
    
    // Geriye dönük uyumluluk: MapView ve diğer eski view'ların bozulmaması için
    var name: String { businessName }
    
    // Backend'den PostGIS ile parçalanarak gelen gerçek koordinatlar
    let latitude: Double
    let longitude: Double
    
    // UI Uyumluluğu (MockData/AppRestaurant yapısı bozulmasın diye geçici değerler)
    var cuisine: String { "Türk Mutfağı" }
    var rating: Double { 4.5 }
    var reviewCount: Int { 120 }
    var distance: String { "Yakında" }
    var priceRange: String { "₺₺" }
    var tags: [String] { ["Lezzetli", "Popüler"] }
    var emoji: String { "🍽️" }
    var isOpen: Bool { true }
    var deliveryTime: String { "20-30 dk" }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case ownerId = "owner_id"
        case businessName = "business_name"
        case address
        case latitude
        case longitude
    }
}
