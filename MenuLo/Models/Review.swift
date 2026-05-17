//
//  Review.swift
//  MenuLo
//
//  MenuLo/Models/Review.swift
//
//  Restoran yorum/değerlendirme modeli. Üç kategorili (Lezzet, Servis, Tutum)
//  opsiyonel puan + içerik metni taşır. AppRestaurant naming pattern'iyle
//  uyumlu olsun diye AppReview.
//
//  REST sözleşmesi:
//    GET  /api/restaurants/:id/reviews   → public, ReviewListResponse
//    POST /api/restaurants/:id/reviews   → authed, body: ReviewSubmitPayload, ReviewResponse
//

import Foundation

// MARK: - Review Reply (işletme yanıtı)
struct ReviewReply: Codable, Equatable {
    let replyId: Int
    let content: String
    let createdAt: String
    let authorName: String?
}

// MARK: - AppReview (GET response item)
// Sadece Decodable — sunucudan gelir, geri gönderilmez. Encodable sentezi
// flat reply alanları (reply_id, reply_content...) yüzünden başarısız olur;
// hiç encode etmiyoruz, kaldırdık.
struct AppReview: Decodable, Identifiable, Equatable {
    let reviewId: Int
    let restaurantId: Int
    let userId: Int
    let userName: String?
    let content: String?
    let taste: Int?
    let service: Int?
    let attitude: Int?
    let createdAt: String
    var reply: ReviewReply?

    var id: Int { reviewId }

    /// Backend ISO 8601 formatında gönderiyor (PostgreSQL TIMESTAMP WITH TIME ZONE → JSON.stringify).
    /// Hem fractional hem standard formatı denenir; başarısızsa nil.
    var date: Date? {
        Self.isoFractional.date(from: createdAt) ?? Self.iso.date(from: createdAt)
    }

    /// 1-5 aralığında ortalama; hiç puan verilmemişse nil.
    var averageRating: Double? {
        let ratings = [taste, service, attitude].compactMap { $0 }
        guard !ratings.isEmpty else { return nil }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }

    enum CodingKeys: String, CodingKey {
        case reviewId      = "review_id"
        case restaurantId  = "restaurant_id"
        case userId        = "user_id"
        case userName      = "user_name"
        case content
        case taste         = "rating_taste"
        case service       = "rating_service"
        case attitude      = "rating_attitude"
        case createdAt     = "created_at"
        // Backend LEFT JOIN ile flat alanlar gönderiyor; reply yoksa hepsi null
        case replyId           = "reply_id"
        case replyContent      = "reply_content"
        case replyCreatedAt    = "reply_created_at"
        case replyAuthorName   = "reply_author_name"
    }

    /// RestaurantDetail.swift'teki defansif decoder pattern'iyle uyumlu — backend
    /// alanları opsiyonel olarak döndürebilir, çökmek yerine nil tutuyoruz.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.reviewId      = try c.decode(Int.self, forKey: .reviewId)
        self.restaurantId  = (try? c.decode(Int.self, forKey: .restaurantId)) ?? 0
        self.userId        = (try? c.decode(Int.self, forKey: .userId)) ?? 0
        self.userName      = try? c.decode(String.self, forKey: .userName)
        self.content       = try? c.decode(String.self, forKey: .content)
        self.taste         = try? c.decode(Int.self, forKey: .taste)
        self.service       = try? c.decode(Int.self, forKey: .service)
        self.attitude      = try? c.decode(Int.self, forKey: .attitude)
        self.createdAt     = (try? c.decode(String.self, forKey: .createdAt)) ?? ""

        // Reply alanları LEFT JOIN ile flat geliyor; reply_id varsa nesneyi kur
        if let rid = try? c.decode(Int.self, forKey: .replyId),
           let rContent = try? c.decode(String.self, forKey: .replyContent) {
            self.reply = ReviewReply(
                replyId:    rid,
                content:    rContent,
                createdAt:  (try? c.decode(String.self, forKey: .replyCreatedAt)) ?? "",
                authorName: try? c.decode(String.self, forKey: .replyAuthorName)
            )
        } else {
            self.reply = nil
        }
    }

    private static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    private static let isoFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

// MARK: - Submit Payload (POST body)
struct ReviewSubmitPayload: Encodable {
    let content: String?
    let ratingTaste: Int?
    let ratingService: Int?
    let ratingAttitude: Int?

    enum CodingKeys: String, CodingKey {
        case content
        case ratingTaste     = "rating_taste"
        case ratingService   = "rating_service"
        case ratingAttitude  = "rating_attitude"
    }
}

// MARK: - Response Wrappers
struct ReviewListResponse: Decodable {
    let success: Bool
    let data: [AppReview]
}

struct ReviewResponse: Decodable {
    let success: Bool
    let data: AppReview
}
