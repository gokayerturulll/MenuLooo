//
//  PasswordPayloads.swift
//  MenuLo
//
//  Şifre kurtarma + değiştirme akışı için istek/yanıt DTO'ları.
//
//  REST sözleşmesi:
//    POST /api/auth/forgot-password   body: ForgotPasswordPayload
//    POST /api/auth/reset-password    body: ResetPasswordPayload
//    PUT  /api/auth/change-password   body: ChangePasswordPayload  (auth)
//

import Foundation

struct ForgotPasswordPayload: Encodable {
    let email: String
}

struct ResetPasswordPayload: Encodable {
    let token: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case token
        case newPassword = "newPassword"
    }
}

struct ChangePasswordPayload: Encodable {
    let oldPassword: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case oldPassword
        case newPassword
    }
}

/// Backend her üç endpoint için aynı zarf yapısını döner.
struct GenericMessageResponse: Decodable {
    let success: Bool
    let message: String?
}

// MARK: - Review Reply
struct ReviewReplyPayload: Encodable {
    let content: String
}

struct ReviewReplyResponse: Decodable {
    let success: Bool
    let data: ReplyData

    struct ReplyData: Decodable {
        let replyId: Int
        let reviewId: Int
        let content: String
        let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case replyId   = "reply_id"
            case reviewId  = "review_id"
            case content
            case createdAt = "created_at"
        }
    }
}

// MARK: - Menu Item Photo Upload Response
struct MenuItemPhotoResponse: Decodable {
    let success: Bool
    let data: PhotoData

    struct PhotoData: Decodable {
        let itemId: Int
        let imageUrl: String

        enum CodingKeys: String, CodingKey {
            case itemId   = "item_id"
            case imageUrl = "image_url"
        }
    }
}
