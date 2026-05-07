//
//  RestaurantDetail.swift
//  MenuLo
//
//  MenuLo/Models/RestaurantDetail.swift
//
//  MyBusinessView (işletme profili) için detaylı restoran modeli.
//  Müşteri tarafındaki minimal Restaurant modelinin aksine telefon, web sitesi,
//  açıklama, mutfak tipi ve çalışma saatleri (JSONB) alanlarını taşır.
//
//  REST sözleşmesi:
//    GET /api/restaurants/:rid     → public, RestaurantDetailResponse
//    PUT /api/restaurants/:rid     → ownerOnly, body: RestaurantUpdatePayload
//

import Foundation
import CoreLocation

// MARK: - Working Hours
struct WorkingHours: Codable, Equatable {
    var openHour: Int
    var openMinute: Int
    var closeHour: Int
    var closeMinute: Int
    var openDays: [String: Bool]

    enum CodingKeys: String, CodingKey {
        case openHour    = "open_hour"
        case openMinute  = "open_minute"
        case closeHour   = "close_hour"
        case closeMinute = "close_minute"
        case openDays    = "open_days"
    }

    static let `default` = WorkingHours(
        openHour: 9, openMinute: 0,
        closeHour: 22, closeMinute: 0,
        openDays: [
            "Pazartesi": true,  "Salı": true,  "Çarşamba": true,
            "Perşembe": true,   "Cuma": true,  "Cumartesi": true,
            "Pazar": false
        ]
    )
}

// MARK: - Restaurant Detail (GET response data)
struct RestaurantDetail: Codable, Identifiable {
    let restaurantId: Int
    let ownerId: Int?
    var businessName: String
    var address: String?
    var phone: String?
    var website: String?
    var description: String?
    var cuisineType: String?
    var latitude: Double?
    var longitude: Double?
    var workingHours: WorkingHours?

    var id: Int { restaurantId }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case ownerId      = "owner_id"
        case businessName = "business_name"
        case address, phone, website, description
        case cuisineType  = "cuisine_type"
        case latitude, longitude
        case workingHours = "working_hours"
    }

    /// Backend latitude/longitude'u string olarak da gönderebilir (PostGIS bazen float'u
    /// numeric döndürür). Defansif decoder.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.restaurantId = try c.decode(Int.self, forKey: .restaurantId)
        self.ownerId      = try? c.decode(Int.self, forKey: .ownerId)
        self.businessName = (try? c.decode(String.self, forKey: .businessName)) ?? ""
        self.address      = try? c.decode(String.self, forKey: .address)
        self.phone        = try? c.decode(String.self, forKey: .phone)
        self.website      = try? c.decode(String.self, forKey: .website)
        self.description  = try? c.decode(String.self, forKey: .description)
        self.cuisineType  = try? c.decode(String.self, forKey: .cuisineType)
        self.latitude     = Self.flexibleDouble(c, .latitude)
        self.longitude    = Self.flexibleDouble(c, .longitude)
        self.workingHours = try? c.decode(WorkingHours.self, forKey: .workingHours)
    }

    private static func flexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let d = try? c.decode(Double.self, forKey: key) { return d }
        if let s = try? c.decode(String.self, forKey: key), let d = Double(s) { return d }
        return nil
    }
}

// MARK: - Update Payload (PUT body)
struct RestaurantUpdatePayload: Encodable {
    let businessName: String?
    let address: String?
    let phone: String?
    let website: String?
    let description: String?
    let cuisineType: String?
    let latitude: Double?
    let longitude: Double?
    let workingHours: WorkingHours?

    enum CodingKeys: String, CodingKey {
        case businessName = "business_name"
        case address, phone, website, description
        case cuisineType  = "cuisine_type"
        case latitude, longitude
        case workingHours = "working_hours"
    }
}

// MARK: - Response Wrappers
struct RestaurantDetailResponse: Decodable {
    let success: Bool
    let data: RestaurantDetail
}
