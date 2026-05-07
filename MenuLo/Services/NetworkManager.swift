import Foundation
import SwiftUI

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

class NetworkManager {
    static let shared = NetworkManager()
    
    // Simülatör localhost erişimi. Gerçek cihazda Mac'in IP adresini girmelisin.
    //private let baseURL = "http://localhost:3000/api"
    private let baseURL = "https://utopia-simmering-mandolin.ngrok-free.dev/api" 
    //private let baseURL = "http://10.81.21.76/api"
    @AppStorage("authToken") private var token: String = ""
    
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw NetworkError.badURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        // 1. Status Code Kontrolü En Başta (200-299 dışındakiler)
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorData = try? JSONDecoder().decode(AuthResponse.self, from: data),
               let serverMessage = errorData.message {
                throw NetworkError.serverError(serverMessage)
            }
            throw NetworkError.serverError("Giriş başarısız (Status: \(httpResponse.statusCode))")
        }
        
        // 2. AuthResponse.success Kontrolü
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
        
        let body: [String: String] = [
            "username": name,
            "email": email,
            "password": password,
            "role": role
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }
        
        // 1. Status Code Kontrolü En Başta (200-299 dışındakiler)
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorData = try? JSONDecoder().decode(AuthResponse.self, from: data),
               let serverMessage = errorData.message {
                throw NetworkError.serverError(serverMessage)
            }
            throw NetworkError.serverError("Kayıt başarısız (Status: \(httpResponse.statusCode))")
        }
        
        // 2. AuthResponse.success Kontrolü
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        if !decoded.success {
            throw NetworkError.serverError(decoded.message ?? "Kayıt başarısız.")
        }
        
        return decoded
    }
    
    func fetchRestaurants() async throws -> [Restaurant] {
        guard let url = URL(string: "\(baseURL)/restaurants") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let res = try JSONDecoder().decode(RestaurantResponse.self, from: data)
        return res.data
    }
    
    func fetchRestaurantMenu(restaurantId: Int) async throws -> MenuData {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu") else {
            throw NetworkError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw NetworkError.serverError("Menü getirilemedi (Status: \(httpResponse.statusCode))")
        }

        let decoded = try JSONDecoder().decode(MenuResponse.self, from: data)
        return decoded.data
    }

    // MARK: - Restaurant Profile (MyBusinessView)
    //
    //   GET /api/restaurants/:rid     → public detay
    //   PUT /api/restaurants/:rid     → ownerOnly, body: RestaurantUpdatePayload

    /// Restoran detaylarını çeker (public — token opsiyonel).
    func fetchRestaurantDetails(restaurantId: Int) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(RestaurantDetailResponse.self, from: data).data
    }

    /// Restoran bilgilerini günceller (Bearer + owner zorunlu).
    func updateRestaurantDetails(restaurantId: Int, payload: RestaurantUpdatePayload) async throws -> RestaurantDetail {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(RestaurantDetailResponse.self, from: data).data
    }

    // MARK: - Owner Menu CRUD
    //
    // Aşağıdaki dört method, işletme paneli (MenuManagerView) için yazılmıştır.
    // Backend'de henüz aktif endpoint olmayabilir — sözleşme aşağıdaki gibidir:
    //
    //   GET    /api/restaurants/:rid/menu/items    → flat list
    //   POST   /api/restaurants/:rid/menu/items    → create (body: OwnerMenuItemPayload)
    //   PUT    /api/menu/items/:itemId             → update
    //   DELETE /api/menu/items/:itemId             → delete
    //
    // Tümü Authorization: Bearer <token> gerektirir; backend tarafında
    // owner-only middleware ile korunmalıdır.

    /// İşletmenin kendi menüsünü flat liste olarak çeker.
    func fetchOwnerMenu(restaurantId: Int) async throws -> [OwnerMenuItem] {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let (data, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "GET"))
        try Self.validateStatus(response)
        return try JSONDecoder().decode(OwnerMenuListResponse.self, from: data).data
    }

    /// Yeni menü öğesi oluşturur.
    func createMenuItem(restaurantId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/restaurants/\(restaurantId)/menu/items") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "POST", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(OwnerMenuItemResponse.self, from: data).data
    }

    /// Mevcut menü öğesini günceller.
    func updateMenuItem(itemId: Int, payload: OwnerMenuItemPayload) async throws -> OwnerMenuItem {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)") else {
            throw NetworkError.badURL
        }
        let body = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "PUT", body: body))
        try Self.validateStatus(response, errorPayload: data)
        return try JSONDecoder().decode(OwnerMenuItemResponse.self, from: data).data
    }

    /// Menü öğesini siler.
    func deleteMenuItem(itemId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/menu/items/\(itemId)") else {
            throw NetworkError.badURL
        }
        let (_, response) = try await URLSession.shared.data(for: authedRequest(url: url, method: "DELETE"))
        try Self.validateStatus(response)
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

    private static func validateStatus(_ response: URLResponse, errorPayload: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { throw NetworkError.unknown }
        if (200...299).contains(http.statusCode) { return }

        // Backend "{success:false,message:...}" şemasında bir hata gönderdiyse onu yüzeye çıkar
        if let payload = errorPayload,
           let envelope = try? JSONDecoder().decode(OwnerMenuDeleteResponse.self, from: payload),
           let msg = envelope.message {
            throw NetworkError.serverError(msg)
        }
        throw NetworkError.serverError("İstek başarısız (Status: \(http.statusCode))")
    }
}
