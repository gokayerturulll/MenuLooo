import Foundation
import CoreLocation

struct RestaurantResponse: Codable {
    let success: Bool
    let count: Int?
    let data: [Restaurant]
}

// MARK: - UserStats

struct UserStats: Decodable {
    let visitCount: Int
    let favouriteCount: Int
    let avgRating: Double
    let business: BusinessStats?

    enum CodingKeys: String, CodingKey {
        case visitCount     = "visit_count"
        case favouriteCount = "favourite_count"
        case avgRating      = "avg_rating"
        case business
    }
}

struct BusinessStats: Decodable {
    let restaurantId: Int
    let avgRating: Double
    let reviewCount: Int
    let favCount: Int

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case avgRating    = "avg_rating"
        case reviewCount  = "review_count"
        case favCount     = "fav_count"
    }
}

struct UserStatsResponse: Decodable {
    let success: Bool
    let data: UserStats
}

// MARK: - RestaurantStats

struct RestaurantStats: Decodable {
    let restaurantId: Int
    let avgRating: Double
    let reviewCount: Int
    let priceRange: String

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case avgRating    = "avg_rating"
        case reviewCount  = "review_count"
        case priceRange   = "price_range"
    }
}

struct RestaurantStatsResponse: Decodable {
    let success: Bool
    let data: RestaurantStats
}

// MARK: - Restaurant

struct Restaurant: Codable, Identifiable, Hashable {
    let restaurantId: Int
    let ownerId: Int
    let businessName: String
    let address: String?
    let latitude: Double
    let longitude: Double

    // API'den gelen istatistik alanları (nullable fallback ile)
    let avgRating: Double?
    let reviewCount: Int?
    let priceRange: String?
    let cuisineType: String?
    let categories: [String]?

    /// PostGIS ile hesaplanmış mesafe (metre). `?lat=&lng=` query'si gönderilmediyse nil.
    let distanceM: Double?

    /// Backend'in working_hours JSONB üzerinden hesapladığı anlık açıklık durumu.
    /// working_hours yoksa true döner.
    let isOpenNow: Bool?

    var id: Int { restaurantId }

    static func == (lhs: Restaurant, rhs: Restaurant) -> Bool {
        lhs.restaurantId == rhs.restaurantId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(restaurantId)
    }

    var name: String { businessName }
    var cuisine: String { cuisineType ?? "Restoran" }
    var rating: Double { avgRating ?? 0.0 }
    var reviewCountDisplay: Int { reviewCount ?? 0 }
    var priceRangeDisplay: String { priceRange ?? "₺₺" }
    var tags: [String] {
        if let cats = categories, !cats.isEmpty { return cats }
        return [cuisine]
    }
    var emoji: String { "🍽️" }
    var isOpen: Bool { isOpenNow ?? true }

    /// Mesafeyi kullanıcı dostu metin olarak biçimlendirir.
    /// Backend distance_m göndermediyse "Yakında" döner.
    var distance: String {
        guard let m = distanceM else { return "Yakında" }
        if m < 1000 { return "\(Int(m.rounded())) m" }
        let km = m / 1000
        return String(format: "%.1f km", km)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case ownerId      = "owner_id"
        case businessName = "business_name"
        case address, latitude, longitude
        case avgRating    = "avg_rating"
        case reviewCount  = "review_count"
        case priceRange   = "price_range"
        case cuisineType  = "cuisine_type"
        case categories
        case distanceM    = "distance_m"
        case isOpenNow    = "is_open"
    }
}
