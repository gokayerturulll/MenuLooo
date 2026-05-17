//
//  RestaurantFilter.swift
//  MenuLo
//
//  Discover ve Map ekranlarındaki filtre çekmecesinin durumunu temsil eder.
//  `toQueryItems(userLocation:)` ile backend'in beklediği query string'e
//  serileştirilir.
//

import Foundation
import CoreLocation

// MARK: - Dietary Tag

/// Backend `menu_item.dietary_tags` Türkçe değerleriyle birebir eşleşir.
enum DietaryTag: String, CaseIterable, Identifiable, Codable {
    case vegan      = "Vegan"
    case glutenFree = "Glutensiz"
    case vegetarian = "Vejetaryen"
    case halal      = "Helal"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .vegan:      return "🌱 Vegan"
        case .glutenFree: return "🌾 Glutensiz"
        case .vegetarian: return "🥦 Vejetaryen"
        case .halal:      return "☪️ Helal"
        }
    }
}

// MARK: - Sort Option

enum RestaurantSortOption: String, CaseIterable, Identifiable, Codable {
    case bestMatch   = "best_match"
    case ratingDesc  = "rating_desc"
    case distanceAsc = "distance_asc"
    case priceAsc    = "price_asc"
    case priceDesc   = "price_desc"

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .bestMatch:   return "En İyi Eşleşme"
        case .ratingDesc:  return "En Yüksek Puan"
        case .distanceAsc: return "En Yakın"
        case .priceAsc:    return "En Düşük Fiyat"
        case .priceDesc:   return "En Yüksek Fiyat"
        }
    }
}

// MARK: - Filter

struct RestaurantFilter: Equatable {
    var dietaryTags: Set<DietaryTag> = []
    /// km cinsinden mesafe üst sınırı. `nil` ise mesafe filtresi uygulanmaz.
    var radiusKm: Double? = nil
    var openNow: Bool = false
    var sort: RestaurantSortOption = .bestMatch

    /// Backend'in beklediği query parametrelerine dönüştürür.
    /// Konum yoksa `radius` parametresi atlanır (backend de yok sayar).
    func toQueryItems(userLocation: CLLocationCoordinate2D?) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        if let loc = userLocation {
            items.append(URLQueryItem(name: "lat", value: String(loc.latitude)))
            items.append(URLQueryItem(name: "lng", value: String(loc.longitude)))
            if let r = radiusKm {
                items.append(URLQueryItem(name: "radius", value: String(r)))
            }
        }

        if !dietaryTags.isEmpty {
            let csv = dietaryTags.map(\.rawValue).sorted().joined(separator: ",")
            items.append(URLQueryItem(name: "dietary", value: csv))
        }

        if openNow {
            items.append(URLQueryItem(name: "open_now", value: "true"))
        }

        if sort != .bestMatch {
            items.append(URLQueryItem(name: "sort", value: sort.rawValue))
        }

        return items
    }
}
