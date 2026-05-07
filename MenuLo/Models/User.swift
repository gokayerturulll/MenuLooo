import Foundation

/// Kullanıcı tipi — müşteri veya işletme sahibi. (Geriye dönük uyumluluk için)
enum UserType: String, Codable, CaseIterable {
    case customer = "customer"
    case business = "business"
    
    var displayName: String {
        switch self {
        case .customer: return "Müşteri"
        case .business: return "İşletme"
        }
    }
}

struct User: Codable, Equatable, Identifiable {
    let userId: Int
    let username: String
    let email: String
    let role: String
    /// Sadece işletme (business) kullanıcıları için sahibi olduğu restoranın ID'si.
    /// Backend login response'unda `restaurant_id` alanı varsa decode edilir, yoksa nil.
    let restaurantId: Int?

    var id: Int { userId }

    // Projedeki eski kodların (AuthViewModel, ProfileView vb.) bozulmaması için computed property'ler eklendi
    var name: String { username }

    var userType: UserType {
        if role.lowercased() == "owner" || role.lowercased() == "admin" || role.lowercased() == "business" {
            return .business
        }
        return .customer
    }

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case username, email, role
        case restaurantId = "restaurant_id"
    }

    init(userId: Int, username: String, email: String, role: String, restaurantId: Int? = nil) {
        self.userId = userId
        self.username = username
        self.email = email
        self.role = role
        self.restaurantId = restaurantId
    }

    // Geriye dönük uyumluluk Init:
    init(id: Int, name: String, email: String, userType: UserType, restaurantId: Int? = nil) {
        self.userId = id
        self.username = name
        self.email = email
        self.role = userType == .business ? "Owner" : "Customer"
        self.restaurantId = restaurantId
    }
}

extension User {
    static let example = User(
        userId: 1,
        username: "Gökay",
        email: "gokay@menulo.com",
        role: "Customer"
    )
    
    static let businessExample = User(
        userId: 2,
        username: "Lezzet Durağı",
        email: "info@lezzetduragi.com",
        role: "Owner",
        restaurantId: 1
    )
}
