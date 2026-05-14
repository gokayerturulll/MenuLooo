import Foundation
import SwiftUI

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

    var errorDescription: String? {
        switch self {
        case .serverError(let message): return message
        case .badURL: return "Geçersiz URL adresi."
        case .unknown: return "Bilinmeyen bir hata oluştu."
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

    private init() {}

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = (try? JSONDecoder().decode(AuthResponse.self, from: data))?.message {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("Giriş başarısız (Status: \(httpResponse.statusCode))")
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
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

        let body: [String: String] = ["username": name, "email": email, "password": password, "role": role]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if !(200...299).contains(httpResponse.statusCode) {
            if let msg = (try? JSONDecoder().decode(AuthResponse.self, from: data))?.message {
                throw NetworkError.serverError(msg)
            }
            throw NetworkError.serverError("Kayıt başarısız (Status: \(httpResponse.statusCode))")
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        if !decoded.success {
            throw NetworkError.serverError(decoded.message ?? "Kayıt başarısız.")
        }
        return decoded
    }

    // MARK: - Restaurants

    func fetchRestaurants() async throws -> [Restaurant] {
        guard let url = URL(string: "\(baseURL)/restaurants") else {
            throw NetworkError.badURL
        }

        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NetworkError.serverError("Restoranlar alınamadı.")
        }
        return try JSONDecoder().decode(RestaurantResponse.self, from: data).data
    }

    func fetchRestaurantMenu(restaurantId: Int) async throws -> MenuData {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(MenuResponse.self, from: data).data
    }

    // MARK: - MenuBot AI

    func askMenuBot(restaurantId: Int?, message: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/menubot/ask") else {
            throw NetworkError.badURL
        }
        let payload = AskMenuBotPayload(restaurantId: restaurantId, message: message)
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(MenuBotResponse.self, from: data).data.answer
    }

    // MARK: - Restaurant Profile

    func fetchRestaurantDetails(restaurantId: Int) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(RestaurantDetailResponse.self, from: data).data
    }

    func updateRestaurantDetails(restaurantId: Int, payload: RestaurantUpdatePayload) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(RestaurantDetailResponse.self, from: data).data
    }

    // MARK: - Owner Menu CRUD

    func fetchOwnerMenu(restaurantId: Int) async throws -> [OwnerMenuItem] {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response)
        return try JSONDecoder().decode(OwnerMenuListResponse.self, from: data).data
    }

    func createMenuItem(restaurantId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(OwnerMenuItemResponse.self, from: data).data
    }

    func updateMenuItem(itemId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(OwnerMenuItemResponse.self, from: data).data
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
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        guard let room = try JSONDecoder().decode(RoomResponse.self, from: data).data else {
            throw NetworkError.serverError("Oda verisi alınamadı.")
        }
        return room
    }

    func joinRoom(payload: JoinRoomPayload) async throws -> Room {
        guard let url = URL(string: "\(baseURL)/rooms/join") else { throw NetworkError.badURL }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        guard let room = try JSONDecoder().decode(RoomResponse.self, from: data).data else {
            throw NetworkError.serverError("Oda verisi alınamadı.")
        }
        return room
    }

    // MARK: - Reviews

    func fetchReviews(restaurantId: Int) async throws -> [AppReview] {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/reviews") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(ReviewListResponse.self, from: data).data
    }

    func submitReview(restaurantId: Int, payload: ReviewSubmitPayload) async throws -> AppReview {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/reviews") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await session.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(ReviewResponse.self, from: data).data
    }

    // MARK: - Helpers

    private func authedRequest(url: URL, method: String, body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
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

        if let payload = errorPayload,
           let msg = (try? JSONDecoder().decode(ErrorEnvelope.self, from: payload))?.message {
            throw NetworkError.serverError(msg)
        }
        throw NetworkError.serverError("İstek başarısız (Status: \(http.statusCode))")
    }
}
