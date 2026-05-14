import Foundation

// MARK: - Room (read model)

struct Room: Identifiable, Codable, Equatable {
    let roomId: Int
    let pinCode: String
    let hostId: Int
    let name: String
    let categories: [String]
    let budget: Int
    let maxDistanceKm: Double
    let status: String
    let createdAt: String

    var id: Int { roomId }

    enum CodingKeys: String, CodingKey {
        case roomId        = "room_id"
        case pinCode       = "pin_code"
        case hostId        = "host_id"
        case name, categories, budget, status
        case maxDistanceKm = "max_distance_km"
        case createdAt     = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        roomId        = try c.decode(Int.self, forKey: .roomId)
        pinCode       = try c.decode(String.self, forKey: .pinCode)
        hostId        = (try? c.decode(Int.self, forKey: .hostId)) ?? 0
        name          = (try? c.decode(String.self, forKey: .name)) ?? ""
        categories    = (try? c.decode([String].self, forKey: .categories)) ?? []
        budget        = (try? c.decode(Int.self, forKey: .budget)) ?? 100
        maxDistanceKm = (try? c.decode(Double.self, forKey: .maxDistanceKm)) ?? 3.0
        status        = (try? c.decode(String.self, forKey: .status)) ?? "active"
        createdAt     = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
    }
}

// MARK: - Payloads & Responses

struct CreateRoomPayload: Encodable {
    let name: String
    let categories: [String]
    let budget: Int
    let maxDistanceKm: Double

    enum CodingKeys: String, CodingKey {
        case name, categories, budget
        case maxDistanceKm = "max_distance_km"
    }
}

struct JoinRoomPayload: Encodable {
    let qrCode: String

    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
    }
}

struct RoomResponse: Decodable {
    let success: Bool
    let message: String?
    let data: Room?
}

// MARK: - Socket participant snapshot

struct RoomParticipant: Identifiable, Equatable {
    let id: Int        // user_id
    let socketId: String
}
