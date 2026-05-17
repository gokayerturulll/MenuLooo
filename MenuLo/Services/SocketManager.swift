import Foundation
import OSLog
import SocketIO

// MARK: - SocketManager
// Singleton — Socket.IO bağlantısını ve oda event'lerini yönetir.
// REST ile oda oluşturulduktan / katıldıktan hemen sonra joinRoom() çağrılır.

final class SocketManager: ObservableObject {

    static let shared = SocketManager()

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.menulo", category: "SocketManager")

    // MARK: - Published state

    @Published private(set) var isConnected   = false
    @Published private(set) var activeRoomId: Int?

    var onMemberJoined:     ((Int) -> Void)?
    var onMemberLeft:       ((Int) -> Void)?
    var onVoteUpdate:       ((String, [Int], [Int]) -> Void)?  // (restaurantId, approvedBy, rejectedBy)
    var onMatchFound:       ((String) -> Void)?                // restaurantId
    var onDeckExhausted:    (() -> Void)?                      // tüm destede eşleşme çıkmadı
    // votes: [restaurantId: ["approved": [userId], "rejected": [userId]]]
    // (votes, matchedIds, memberCount, myVotedIds)
    var onSyncRoomState:    (([String: [String: [Int]]], [String], Int, [String]) -> Void)?
    var onJoinRoomRejected: ((String) -> Void)?
    var onConnectionFailed: ((String) -> Void)?
    var onVotingStarted:    (([RoomRestaurant]) -> Void)?      // start_voting → voting_started

    // MARK: - Private

    private var manager: SocketIO.SocketManager?
    private var socket:  SocketIOClient?

    private init() {}

    // MARK: - Bağlantı

    /// JWT token ile sunucuya bağlan.
    /// Eğer soket zaten bağlıysa ya da bağlanıyorsa hiçbir şey yapmaz.
    /// Eğer soket var ama bağlantısı kesilmişse (ör. arka plandan dönüş) yeniden bağlar.
    func connect() {
        if let existing = socket {
            switch existing.status {
            case .connected, .connecting:
                return              // zaten aktif
            default:
                existing.connect()  // var olan soket üzerinden yeniden bağlan
                return
            }
        }

        // İlk kez kurulum
        let token = KeychainHelper.load(forKey: AppConstants.keychainTokenKey) ?? ""
        guard !token.isEmpty,
              let url = URL(string: AppConstants.socketURL) else { return }

        manager = SocketIO.SocketManager(
            socketURL: url,
            config: [
                .connectParams(["token": token]),
                .log(false),
                .compress,
                .reconnects(true),
                .reconnectWait(2),
                .reconnectAttempts(5),
            ]
        )
        socket = manager?.defaultSocket
        registerHandlers()
        socket?.connect()
    }

    /// Aktif bağlantıyı ve oda state'ini tamamen sıfırla.
    /// scenePhase .background olduğunda çağrılır.
    func disconnect() {
        if let roomId = activeRoomId {
            socket?.emit("leave_room", ["room_id": roomId])
        }
        socket?.disconnect()
        socket       = nil
        manager      = nil
        activeRoomId = nil
        DispatchQueue.main.async { self.isConnected = false }
    }

    // MARK: - Oda İşlemleri

    /// REST ile oda oluşturulduktan / katıldıktan sonra çağrılır.
    /// Henüz bağlı değilse önce bağlanır, bağlantı kurulunca `join_room` emit eder.
    func joinRoom(roomId: Int) {
        guard isConnected else {
            connect()
            var didConnect = false

            socket?.once(clientEvent: .connect) { [weak self] _, _ in
                didConnect = true
                self?.emitJoinRoom(roomId: roomId)
            }

            socket?.once(clientEvent: .error) { [weak self] data, _ in
                guard !didConnect else { return }
                let msg = data.first as? String ?? "Bağlantı hatası."
                DispatchQueue.main.async { self?.onConnectionFailed?(msg) }
            }

            // 10 saniye içinde bağlanamazsa hata bildir
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                guard !didConnect else { return }
                self?.onConnectionFailed?("Sunucuya bağlanılamadı. Lütfen internet bağlantınızı kontrol edin.")
            }
            return
        }
        emitJoinRoom(roomId: roomId)
    }

    func leaveRoom(roomId: Int) {
        socket?.emit("leave_room", ["room_id": roomId])
        DispatchQueue.main.async {
            if self.activeRoomId == roomId { self.activeRoomId = nil }
        }
    }

    /// Lobideki kategori tercihlerini sunucuya bildirir.
    func submitCategories(roomId: Int, categories: [String]) {
        socket?.emit("submit_categories", ["room_id": roomId, "categories": categories])
    }

    /// Oda kurucusu oylamayı başlatır; sunucu voting_started ile restoranları gönderir.
    func startVoting(roomId: Int, completion: @escaping (Bool, String?) -> Void) {
        socket?.emitWithAck("start_voting", ["room_id": roomId]).timingOut(after: 10) { data in
            let dict    = data.first as? [String: Any]
            let success = dict?["success"] as? Bool ?? false
            let error   = dict?["error"]   as? String
            DispatchQueue.main.async { completion(success, error) }
        }
    }

    /// Oy gönderir ve sunucudan ack bekler (5 sn timeout).
    /// Ağ hatası veya sunucu reddi durumunda `completion(false)` döner — UI kilidi açılmalı.
    func submitVote(roomId: Int, restaurantId: String, isApproved: Bool,
                    completion: @escaping (Bool) -> Void) {
        socket?.emitWithAck("submit_vote", [
            "room_id":       roomId,
            "restaurant_id": restaurantId,
            "is_approved":   isApproved,
        ]).timingOut(after: 5) { data in
            // Timeout → data == [NSNull()]
            let success = (data.first as? [String: Any])?["success"] as? Bool ?? false
            DispatchQueue.main.async { completion(success) }
        }
    }

    // MARK: - Private Helpers

    private func emitJoinRoom(roomId: Int) {
        socket?.emit("join_room", ["room_id": roomId])
        DispatchQueue.main.async { self.activeRoomId = roomId }
    }

    private func registerHandlers() {
        socket?.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async { self?.isConnected = true }
        }

        socket?.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async { self?.isConnected = false }
        }

        socket?.on(clientEvent: .error) { [weak self] data, _ in
            if let msg = data.first as? String {
                self?.logger.error("Hata: \(msg, privacy: .public)")
            }
        }

        socket?.on("member_joined") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["user_id"] as? Int else { return }
            DispatchQueue.main.async { self?.onMemberJoined?(userId) }
        }

        socket?.on("member_left") { [weak self] data, _ in
            guard let dict   = data.first as? [String: Any],
                  let userId = dict["user_id"] as? Int else { return }
            DispatchQueue.main.async { self?.onMemberLeft?(userId) }
        }

        socket?.on("vote_update") { [weak self] data, _ in
            guard let dict         = data.first as? [String: Any],
                  let restaurantId = dict["restaurant_id"] as? String,
                  let approvedBy   = dict["approved_by"]   as? [Int],
                  let rejectedBy   = dict["rejected_by"]   as? [Int] else { return }
            DispatchQueue.main.async { self?.onVoteUpdate?(restaurantId, approvedBy, rejectedBy) }
        }

        socket?.on("match_found") { [weak self] data, _ in
            guard let dict         = data.first as? [String: Any],
                  let restaurantId = dict["restaurant_id"] as? String else { return }
            DispatchQueue.main.async { self?.onMatchFound?(restaurantId) }
        }

        socket?.on("deck_exhausted") { [weak self] _, _ in
            DispatchQueue.main.async { self?.onDeckExhausted?() }
        }

        socket?.on("sync_room_state") { [weak self] data, _ in
            guard let dict = data.first as? [String: Any],
                  let memberCount = dict["member_count"] as? Int else { return }

            var parsedVotes: [String: [String: [Int]]] = [:]
            if let rawVotes = dict["votes"] as? [String: Any] {
                for (restaurantId, voteData) in rawVotes {
                    guard let voteDict = voteData as? [String: Any] else { continue }
                    parsedVotes[restaurantId] = [
                        "approved": voteDict["approved"] as? [Int] ?? [],
                        "rejected": voteDict["rejected"] as? [Int] ?? [],
                    ]
                }
            }
            let matchedIds = dict["matched_restaurant_ids"] as? [String] ?? []
            let myVotedIds = dict["my_voted_ids"] as? [String] ?? []
            DispatchQueue.main.async { self?.onSyncRoomState?(parsedVotes, matchedIds, memberCount, myVotedIds) }
        }

        socket?.on("join_room_rejected") { [weak self] data, _ in
            let reason = (data.first as? [String: Any])?["reason"] as? String ?? "Erişim reddedildi."
            DispatchQueue.main.async { self?.onJoinRoomRejected?(reason) }
        }

        socket?.on("voting_started") { [weak self] data, _ in
            guard let dict       = data.first as? [String: Any],
                  let rawList    = dict["restaurants"] as? [[String: Any]] else { return }
            let decoder = JSONDecoder()
            let restaurants: [RoomRestaurant] = rawList.compactMap { raw in
                guard let jsonData = try? JSONSerialization.data(withJSONObject: raw) else { return nil }
                return try? decoder.decode(RoomRestaurant.self, from: jsonData)
            }
            DispatchQueue.main.async { self?.onVotingStarted?(restaurants) }
        }
    }
}
