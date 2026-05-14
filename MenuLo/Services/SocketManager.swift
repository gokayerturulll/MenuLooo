import Foundation
import SocketIO

// MARK: - SocketManager
// Singleton — Socket.IO bağlantısını ve oda event'lerini yönetir.
// REST ile oda oluşturulduktan / katıldıktan hemen sonra joinRoom() çağrılır.

final class SocketManager: ObservableObject {

    static let shared = SocketManager()

    // MARK: - Published state

    @Published private(set) var isConnected   = false
    @Published private(set) var activeRoomId: Int?

    var onMemberJoined: ((Int) -> Void)?
    var onMemberLeft:   ((Int) -> Void)?

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
            socket?.once(clientEvent: .connect) { [weak self] _, _ in
                self?.emitJoinRoom(roomId: roomId)
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

        socket?.on(clientEvent: .error) { _, data in
            if let msg = data.first as? String {
                print("[Socket] Hata:", msg)
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
    }
}
