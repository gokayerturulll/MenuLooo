import Foundation

struct MenuResponse: Codable {
    let success: Bool
    let data: MenuData
}

struct MenuData: Codable {
    let menuId: Int?
    let restaurantId: Int?
    let categories: [MenuCategory]

    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case restaurantId = "restaurant_id"
        case categories
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.menuId = MenuData.flexibleInt(c, .menuId)
        self.restaurantId = MenuData.flexibleInt(c, .restaurantId)
        self.categories = (try? c.decode([MenuCategory].self, forKey: .categories)) ?? []
    }

    private static func flexibleInt(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let v = try? c.decode(Int.self, forKey: key) { return v }
        if let s = try? c.decode(String.self, forKey: key), let v = Int(s) { return v }
        return nil
    }
}

struct MenuCategory: Codable, Identifiable {
    let categoryId: Int
    let categoryName: String
    let items: [MenuDetailItem]

    var id: Int { categoryId }

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case categoryName = "category_name"
        case items
    }
}

struct MenuDetailItem: Codable, Identifiable {
    let itemId: Int
    let name: String
    let price: Double
    let description: String?
    let imageUrl: String?
    let dietaryTags: [String]?

    var id: Int { itemId }

    var formattedPrice: String {
        String(format: "%.2f ₺", price)
    }

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, price, description
        case imageUrl = "image_url"
        case dietaryTags = "dietary_tags"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.itemId = try c.decode(Int.self, forKey: .itemId)
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try? c.decode(String.self, forKey: .description)
        self.imageUrl = try? c.decode(String.self, forKey: .imageUrl)
        self.dietaryTags = try? c.decode([String].self, forKey: .dietaryTags)

        if let d = try? c.decode(Double.self, forKey: .price) {
            self.price = d
        } else if let s = try? c.decode(String.self, forKey: .price), let d = Double(s) {
            self.price = d
        } else {
            self.price = 0
        }
    }
}
