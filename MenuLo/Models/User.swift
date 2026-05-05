//
//  User.swift
//  MenuLo
//
//  Kullanıcı veri modeli.
//  Backend'den gelen JSON verisini Swift struct'ına dönüştürmek (decode)
//  ve Swift nesnesini JSON'a çevirmek (encode) için Codable protokolünü kullanır.
//

import Foundation

/// Kullanıcı tipi — müşteri veya işletme sahibi.
///
/// Backend'de "customer" veya "business" string olarak saklanır.
/// `Codable` sayesinde JSON <-> Swift dönüşümü otomatik yapılır.
enum UserType: String, Codable, CaseIterable {
    case customer = "customer"
    case business = "business"
    
    /// Kullanıcı tipinin Türkçe görüntüleme metni
    var displayName: String {
        switch self {
        case .customer: return "Müşteri"
        case .business: return "İşletme"
        }
    }
}

/// Kullanıcı veri modeli.
///
/// Bu struct, backend API'den dönen kullanıcı verisini temsil eder.
/// `Codable` → JSON encode/decode desteği
/// `Identifiable` → SwiftUI `List` ve `ForEach` içinde doğrudan kullanılabilir
/// `Equatable` → İki User nesnesinin karşılaştırılabilmesi
///
/// Örnek JSON:
/// ```json
/// {
///     "id": 1,
///     "name": "Gökay",
///     "email": "gokay@example.com",
///     "userType": "customer",
///     "profileImageURL": "https://...",
///     "createdAt": "2026-05-05T12:00:00Z"
/// }
/// ```
struct User: Codable, Identifiable, Equatable {
    
    /// Kullanıcının benzersiz kimlik numarası (MySQL primary key)
    let id: Int
    
    /// Kullanıcının tam adı
    var name: String
    
    /// E-posta adresi (giriş için kullanılır)
    var email: String
    
    /// Kullanıcı tipi: müşteri mi, işletme sahibi mi?
    var userType: UserType
    
    /// Profil fotoğrafı URL'i (opsiyonel)
    var profileImageURL: String?
    
    /// Hesap oluşturma tarihi (opsiyonel — backend'den gelebilir)
    var createdAt: String?
    
    // MARK: - CodingKeys
    
    /// JSON anahtar isimleriyle Swift property isimlerini eşleştirir.
    /// Backend'de snake_case, Swift'te camelCase kullanıldığı durumlar için.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case userType = "user_type"
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
    }
}

// MARK: - Preview / Test için Örnek Veri

extension User {
    /// SwiftUI Preview ve testlerde kullanılacak örnek kullanıcı
    static let example = User(
        id: 1,
        name: "Gökay",
        email: "gokay@menulo.com",
        userType: .customer,
        profileImageURL: nil,
        createdAt: "2026-05-05T12:00:00Z"
    )
    
    /// İşletme sahibi örneği
    static let businessExample = User(
        id: 2,
        name: "Lezzet Durağı",
        email: "info@lezzetduragi.com",
        userType: .business,
        profileImageURL: nil,
        createdAt: "2026-05-05T12:00:00Z"
    )
}
