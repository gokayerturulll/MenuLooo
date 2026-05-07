//
//  OwnerMenuItem.swift
//  MenuLo
//
//  MenuLo/Models/OwnerMenuItem.swift
//
//  İşletme yönetim paneli (MenuManagerView) için CRUD modeli.
//  Müşteri tarafındaki MenuDetailItem'dan farkı: kategori, aktif/pasif ve
//  Yeşil Menü flag'leri burada doğrudan ürün üzerinde taşınır.
//
//  Beklenen REST sözleşmesi:
//   GET    /api/restaurants/:rid/menu/items    → list (Bearer + owner)
//   POST   /api/restaurants/:rid/menu/items    → create
//   PUT    /api/menu/items/:itemId             → update
//   DELETE /api/menu/items/:itemId             → delete
//

import Foundation

struct OwnerMenuItem: Codable, Identifiable, Equatable {
    let itemId: Int
    var name: String
    var price: Double
    var description: String?
    var category: String
    var isGreenMenu: Bool
    var isAvailable: Bool
    var imageUrl: String?

    var id: Int { itemId }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, price, description, category
        case isGreenMenu = "is_green_menu"
        case isAvailable = "is_available"
        case imageUrl    = "image_url"
    }

    /// Backend price'ı string ya da number döndürebilir — her iki şemayı da tolere et.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.itemId = try c.decode(Int.self, forKey: .itemId)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try? c.decode(String.self, forKey: .description)
        self.category = (try? c.decode(String.self, forKey: .category)) ?? "Diğer"
        self.isGreenMenu = (try? c.decode(Bool.self, forKey: .isGreenMenu)) ?? false
        self.isAvailable = (try? c.decode(Bool.self, forKey: .isAvailable)) ?? true
        self.imageUrl    = try? c.decode(String.self, forKey: .imageUrl)

        if let d = try? c.decode(Double.self, forKey: .price) {
            self.price = d
        } else if let s = try? c.decode(String.self, forKey: .price), let d = Double(s) {
            self.price = d
        } else {
            self.price = 0
        }
    }

    init(itemId: Int, name: String, price: Double, description: String?,
         category: String, isGreenMenu: Bool, isAvailable: Bool, imageUrl: String? = nil) {
        self.itemId = itemId
        self.name = name
        self.price = price
        self.description = description
        self.category = category
        self.isGreenMenu = isGreenMenu
        self.isAvailable = isAvailable
        self.imageUrl = imageUrl
    }
}

/// POST/PUT istek body'si.
struct OwnerMenuItemPayload: Encodable {
    let name: String
    let price: Double
    let description: String?
    let category: String
    let isGreenMenu: Bool
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case name, price, description, category
        case isGreenMenu = "is_green_menu"
        case isAvailable = "is_available"
    }
}

// MARK: - Response Wrappers

struct OwnerMenuListResponse: Decodable {
    let success: Bool
    let data: [OwnerMenuItem]
}

struct OwnerMenuItemResponse: Decodable {
    let success: Bool
    let data: OwnerMenuItem
}

struct OwnerMenuDeleteResponse: Decodable {
    let success: Bool
    let message: String?
}
