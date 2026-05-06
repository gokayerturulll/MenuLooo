import Foundation

struct AuthResponse: Codable {
    let success: Bool
    let message: String?
    let token: String?
    let user: User?
}
