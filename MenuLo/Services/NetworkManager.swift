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
}
