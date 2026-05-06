import Foundation
import SwiftUI

class NetworkManager {
    static let shared = NetworkManager()
    
    // Simülatör localhost erişimi. Gerçek cihazda Mac'in IP adresini girmelisin.
    private let baseURL = "http://localhost:3000/api"
    
    @AppStorage("authToken") private var token: String = ""
    
    private init() {}
    
    func login(email: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            if let errorData = try? JSONDecoder().decode(AuthResponse.self, from: data) {
                return errorData
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }
    
    func register(name: String, email: String, password: String, role: String) async throws -> AuthResponse {
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            throw URLError(.badURL)
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
        
        // Backend'den başarılı olan durumlarda da hata mesajlarında da AuthResponse modeli döner.
        // Hata durumunda success false olacak şekilde parse edip kullanabilmemiz için decode işlemini önce yapıyoruz:
        if let decodedResponse = try? JSONDecoder().decode(AuthResponse.self, from: data) {
            return decodedResponse
        }
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AuthResponse.self, from: data)
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
}
