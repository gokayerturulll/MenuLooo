import Foundation

// MARK: - Room (read model)
// budget ve maxDistanceKm kaldırıldı — filtreler lobi içinde yalnızca kategori bazlıdır.

struct Room: Identifiable, Codable, Equatable {
    let roomId: Int
    let pinCode: String
    let hostId: Int
    let name: String
    let categories: [String]
    let status: String
    let createdAt: String

    var id: Int { roomId }

    enum CodingKeys: String, CodingKey {
        case roomId    = "room_id"
        case pinCode   = "pin_code"
        case hostId    = "host_id"
        case name, categories, status
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        roomId     = try c.decode(Int.self, forKey: .roomId)
        pinCode    = try c.decode(String.self, forKey: .pinCode)
        hostId     = (try? c.decode(Int.self, forKey: .hostId)) ?? 0
        name       = (try? c.decode(String.self, forKey: .name)) ?? ""
        categories = (try? c.decode([String].self, forKey: .categories)) ?? []
        status     = (try? c.decode(String.self, forKey: .status)) ?? "active"
        createdAt  = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
    }

    init(roomId: Int, pinCode: String, hostId: Int, name: String,
         categories: [String], status: String, createdAt: String) {
        self.roomId     = roomId
        self.pinCode    = pinCode
        self.hostId     = hostId
        self.name       = name
        self.categories = categories
        self.status     = status
        self.createdAt  = createdAt
    }
}

// MARK: - Payloads & Responses

struct CreateRoomPayload: Encodable {
    let name: String
    let categories: [String]
}

struct JoinRoomPayload: Encodable {
    let qrCode: String

    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
    }
}

struct RoomResponse: Decodable {
    let success: Bool
    let message: String?
    let data: Room?
}

// MARK: - Socket participant snapshot

struct RoomParticipant: Identifiable, Equatable {
    let id: Int        // user_id
    let socketId: String
}

// MARK: - Vote State (Faz 3)

struct RestaurantVote: Identifiable, Equatable {
    let restaurantId: String
    var approvedBy: [Int]
    var rejectedBy: [Int]
    var id: String { restaurantId }
}

// MARK: - Oda Restoran Havuzu (Faz 4)

struct RoomRestaurant: Identifiable, Codable {
    let restaurantId: Int
    let ownerId: Int
    let businessName: String
    let address: String?
    let cuisineType: String?
    let categories: [String]
    let latitude: Double
    let longitude: Double
    let phone: String?
    let website: String?

    var id: Int { restaurantId }
    var name: String { businessName }
    var cuisineDisplay: String { categories.first ?? cuisineType ?? "Restoran" }

    var categoryEmoji: String {
        let source = (categories.first ?? cuisineType ?? "").lowercased()
        if source.contains("pizza")                                              { return "🍕" }
        if source.contains("hamburger") || source.contains("burger")            { return "🍔" }
        if source.contains("sushi")                                              { return "🍣" }
        if source.contains("döner") || source.contains("kebap")                 { return "🥙" }
        if source.contains("vegan")                                              { return "🌱" }
        if source.contains("salata")                                             { return "🥗" }
        if source.contains("deniz") || source.contains("balık")                 { return "🐟" }
        if source.contains("ramen")                                              { return "🍜" }
        if source.contains("tatlı") || source.contains("pastane")               { return "🍰" }
        if source.contains("steak")                                              { return "🥩" }
        if source.contains("makarna")                                            { return "🍝" }
        if source.contains("çorba")                                              { return "🍲" }
        if source.contains("kahve")                                              { return "☕" }
        return "🍽️"
    }

    var asRestaurant: Restaurant {
        Restaurant(
            restaurantId: restaurantId,
            ownerId:      ownerId,
            businessName: businessName,
            address:      address,
            latitude:     latitude,
            longitude:    longitude,
            avgRating:    nil,
            reviewCount:  nil,
            priceRange:   nil,
            cuisineType:  cuisineType,
            categories:   categories,
            distanceM:    nil,
            isOpenNow:    nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case ownerId      = "owner_id"
        case businessName = "business_name"
        case address
        case cuisineType  = "cuisine_type"
        case categories
        case latitude
        case longitude
        case phone
        case website
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        restaurantId = try c.decode(Int.self, forKey: .restaurantId)
        ownerId      = try c.decode(Int.self, forKey: .ownerId)
        businessName = try c.decode(String.self, forKey: .businessName)
        address      = try? c.decode(String.self, forKey: .address)
        cuisineType  = try? c.decode(String.self, forKey: .cuisineType)
        categories   = (try? c.decode([String].self, forKey: .categories)) ?? []
        latitude     = (try? c.decode(Double.self, forKey: .latitude)) ?? 0
        longitude    = (try? c.decode(Double.self, forKey: .longitude)) ?? 0
        phone        = try? c.decode(String.self, forKey: .phone)
        website      = try? c.decode(String.self, forKey: .website)
    }
}

struct RoomRestaurantsResponse: Decodable {
    let success: Bool
    let data: [RoomRestaurant]
}
