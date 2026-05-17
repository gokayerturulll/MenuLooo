import Foundation
import SwiftUI
import CoreLocation

extension Notification.Name {
    static let userSessionExpired = Notification.Name("userSessionExpired")
}

// MARK: - MenuBot DTOs

struct AskMenuBotPayload: Encodable {
    let restaurantId: Int?
    let message: String
}

struct MenuBotReferencedItem: Decodable {
    let itemId: Int?
    let name: String
    let price: Double?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case name, price, category
    }
}

struct MenuBotAnswer: Decodable {
    let answer: String
    let referencedItems: [MenuBotReferencedItem]?

    enum CodingKeys: String, CodingKey {
        case answer
        case referencedItems = "referenced_items"
    }
}

struct MenuBotResponse: Decodable {
    let success: Bool
    let data: MenuBotAnswer
}

enum NetworkError: LocalizedError {
    case serverError(String)
    case badURL
    case unknown
    case unauthorized           // 401 — token süresi dolmuş veya geçersiz
    case rateLimited            // 429 — çok fazla istek
    case offline                // URLError.notConnectedToInternet

    var errorDescription: String? {
        switch self {
        case .serverError(let message): return message
        case .badURL:        return "Geçersiz URL adresi."
        case .unknown:       return "Bilinmeyen bir hata oluştu."
        case .unauthorized:  return "Oturum süreniz dolmuş. Lütfen tekrar giriş yapın."
        case .rateLimited:   return "Çok fazla istek gönderildi. Lütfen bekleyin."
        case .offline:       return "İnternet bağlantısı yok."
        }
    }
}

// MARK: - NetworkManager

class NetworkManager {
    static let shared = NetworkManager()

    private let baseURL = AppConstants.apiBaseURL

    /// URLSession with explicit timeout — prevents requests from hanging indefinitely.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = AppConstants.requestTimeout
        config.timeoutIntervalForResource = AppConstants.requestTimeout * 2
        return URLSession(configuration: config)
    }()

    private var token: String { KeychainHelper.load(forKey: AppConstants.keychainTokenKey) ?? "" }

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = (try? decoder.decode(AuthResponse.self, from: data))?.message {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("Giriş başarısız (Status: \(httpResponse.statusCode))")
        }

        let decoded = try decoder.decode(AuthResponse.self, from: data)
        if !decoded.success {
            throw NetworkError.serverError(decoded.message ?? "Giriş başarısız.")
        }
        return decoded
    }

    func register(name: String, email: String, password: String, role: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let body: [String: String] = ["username": name, "email": email, "password": password, "role": role]
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = (try? decoder.decode(AuthResponse.self, from: data))?.message {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("Kayıt başarısız (Status: \(httpResponse.statusCode))")
        }

        let decoded = try decoder.decode(AuthResponse.self, from: data)
        if !decoded.success {
            throw NetworkError.serverError(decoded.message ?? "Kayıt başarısız.")
        }
        return decoded
    }

    // MARK: - Password Recovery & Change

    /// POST /auth/forgot-password — backend her zaman 200 döner (kullanıcı varlığı ifşa edilmez).
    func forgotPassword(email: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else { throw NetworkError.badURL }
        let body = try encoder.encode(ForgotPasswordPayload(email: email))
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
    }

    /// PUT /auth/change-password — auth token gerekli.
    func changePassword(oldPassword: String, newPassword: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/change-password") else { throw NetworkError.badURL }
        let payload = ChangePasswordPayload(oldPassword: oldPassword, newPassword: newPassword)
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
    }

    // MARK: - Restaurants

    /// GET /api/restaurants — opsiyonel filtre ve kullanıcı konumuyla.
    /// - `filter`: dietary, radius, open_now, sort parametrelerini içerir.
    /// - `userLocation`: lat/lng query parametresi olarak gider; backend `distance_m`
    ///   alanını doldurur ve `radius` filtresi aktif olabilir.
    func fetchRestaurants(filter: RestaurantFilter = RestaurantFilter(),
                          userLocation: CLLocationCoordinate2D? = nil) async throws -> [Restaurant] {
        guard var components = URLComponents(string: "\(baseURL)/restaurants") else {
            throw NetworkError.badURL
        }
        let items = filter.toQueryItems(userLocation: userLocation)
        components.queryItems = items.isEmpty ? nil : items

        guard let url = components.url else { throw NetworkError.badURL }

        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError("Restoranlar alınamadı.")
        }
        return try decoder.decode(RestaurantResponse.self, from: data).data
    }

    func fetchRestaurantMenu(restaurantId: Int) async throws -> MenuData {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(MenuResponse.self, from: data).data
    }

    // MARK: - MenuBot AI

    func askMenuBot(restaurantId: Int?, message: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/menubot/ask") else {
            throw NetworkError.badURL
        }
        let payload = AskMenuBotPayload(restaurantId: restaurantId, message: message)
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(MenuBotResponse.self, from: data).data.answer
    }

    // MARK: - Restaurant Profile

    func fetchRestaurantDetails(restaurantId: Int) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(RestaurantDetailResponse.self, from: data).data
    }

    func updateRestaurantDetails(restaurantId: Int, payload: RestaurantUpdatePayload) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(RestaurantDetailResponse.self, from: data).data
    }

    // MARK: - Owner Menu CRUD

    func fetchOwnerMenu(restaurantId: Int) async throws -> [OwnerMenuItem] {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response)
        return try decoder.decode(OwnerMenuListResponse.self, from: data).data
    }

    func createMenuItem(restaurantId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(OwnerMenuItemResponse.self, from: data).data
    }

    func updateMenuItem(itemId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(OwnerMenuItemResponse.self, from: data).data
    }

    func deleteMenuItem(itemId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)") else {
            throw NetworkError.badURL
        }
        let (_, response) = try await session.data(for: authedRequest(url: url, method: "DELETE"))
        try Self.validateStatus(response)
    }

    // MARK: - Rooms

    func createRoom(payload: CreateRoomPayload) async throws -> Room {
        guard let url = URL(string: "\(baseURL)/rooms/create") else { throw NetworkError.badURL }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        guard let room = try decoder.decode(RoomResponse.self, from: data).data else {
            throw NetworkError.serverError("Oda verisi alınamadı.")
        }
        return room
    }

    func joinRoom(payload: JoinRoomPayload) async throws -> Room {
        guard let url = URL(string: "\(baseURL)/rooms/join") else { throw NetworkError.badURL }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        guard let room = try decoder.decode(RoomResponse.self, from: data).data else {
            throw NetworkError.serverError("Oda verisi alınamadı.")
        }
        return room
    }

    func fetchRoomRestaurants(roomId: Int) async throws -> [RoomRestaurant] {
        guard let url = URL(string: "\(baseURL)/rooms/\(roomId)/restaurants") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(RoomRestaurantsResponse.self, from: data).data
    }

    // MARK: - Reviews

    func fetchReviews(restaurantId: Int) async throws -> [AppReview] {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/reviews") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(ReviewListResponse.self, from: data).data
    }

    func submitReview(restaurantId: Int, payload: ReviewSubmitPayload) async throws -> AppReview {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/reviews") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(ReviewResponse.self, from: data).data
    }

    /// POST /restaurants/{id}/reviews/{reviewId}/reply — sadece restoran sahibi.
    func submitReviewReply(restaurantId: Int, reviewId: Int, content: String) async throws -> ReviewReplyResponse.ReplyData {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/reviews/\(reviewId)/reply") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(ReviewReplyPayload(content: content))
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(ReviewReplyResponse.self, from: data).data
    }

    // MARK: - Push Notifications

    func registerDeviceToken(_ token: String) async throws {
        guard let url = URL(string: "\(baseURL)/notifications/register") else {
            throw NetworkError.badURL
        }
        let body = try encoder.encode(["device_token": token, "platform": "ios"])
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
    }

    // MARK: - Stats

    func fetchUserStats() async throws -> UserStats {
        guard let url = URL(string: "\(baseURL)/auth/me/stats") else { throw NetworkError.badURL }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(UserStatsResponse.self, from: data).data
    }

    func fetchRestaurantStats(restaurantId: Int) async throws -> RestaurantStats {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/stats") else { throw NetworkError.badURL }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(RestaurantStatsResponse.self, from: data).data
    }

    // MARK: - Menu Item Photo Upload (multipart/form-data)

    /// POST /menu/items/{id}/photo — multipart upload, field name: "photo".
    /// Backend ham byte alır, lokal /uploads/menu/ klasörüne yazar, image_url döner.
    func uploadMenuItemPhoto(itemId: Int, imageData: Data, filename: String = "photo.jpg",
                             mimeType: String = "image/jpeg") async throws -> String {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)/photo") else {
            throw NetworkError.badURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        try Self.validateStatus(response, errorPayload: data)
        return try decoder.decode(MenuItemPhotoResponse.self, from: data).data.imageUrl
    }

    // MARK: - Helpers

    private func authedRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        if !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = body
        return req
    }

    /// Generic error envelope — tüm backend hata yanıtlarını parse eder.
    private struct ErrorEnvelope: Decodable { let message: String? }

    private static func validateStatus(_ response: URLResponse, errorPayload: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { throw NetworkError.unknown }
        if (200...299).contains(http.statusCode) { return }

        switch http.statusCode {
        case 401:
            // Tüm ViewModel'leri bilgilendirmek için NotificationCenter kullan
            NotificationCenter.default.post(name: .userSessionExpired, object: nil)
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        default:
            if let payload = errorPayload,
               let msg = (try? JSONDecoder().decode(ErrorEnvelope.self, from: payload))?.message {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("İstek başarısız (Status: \(http.statusCode))")
        }
    }
}
