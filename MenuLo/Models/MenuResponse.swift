import Foundation

struct MenuResponse: Codable {
    let success: Bool
    let data: MenuData
}

struct MenuData: Codable {
    let menuId: Int
    let restaurantId: Int
    let categories: [MenuCategory]
    
    enum CodingKeys: String, CodingKey {
        case menuId = "menu_id"
        case restaurantId = "restaurant_id"
        case categories
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
    let price: Double // Parsed as a numeric Double
    let description: String?
    let imageUrl: String?
    let dietaryTags: [String]?
    
    var id: Int { itemId }
    
    var formattedPrice: String {
        return String(format: "%.2f ₺", price)
    }
    
    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, price, description
        case imageUrl = "image_url"
        case dietaryTags = "dietary_tags"
    }
}
