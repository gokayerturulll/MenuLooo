import Foundation
import Combine
import UIKit
import CoreImage

// MARK: - RoomViewModel

@MainActor
final class RoomViewModel: ObservableObject {

    // MARK: - UI State

    @Published var isLoading:           Bool                     = false
    @Published var errorMessage:        String?
    @Published var currentRoom:         Room?
    @Published var participantIds:      [Int]                    = []
    @Published var isSocketConnected:   Bool                     = false
    @Published private(set) var qrCodeImage: UIImage?
    @Published var votes:               [String: RestaurantVote] = [:]
    @Published var matchedRestaurantId: String?

    // Lobi içi kategori tercihleri — bütçe ve mesafe kaldırıldı.
    @Published var selectedCategories:  Set<String>              = []

    // Faz 4: gerçek restoran havuzu ve oy izleme
    @Published var roomRestaurants:    [RoomRestaurant] = []
    @Published var votedRestaurantIds: Set<String>      = []
    private var pendingVotes:          Set<String>      = []
    private var deckExhaustedTask:     Task<Void, Never>?

    // Faz 5: deste tükenince geçiş animasyonu için
    @Published var isDeckExhausted: Bool = false
    // Voting started — ActiveRoomView bu flag'i izleyerek RoomVotingView'a geçer
    @Published var isVotingStarted: Bool = false

    private let network      = NetworkManager.shared
    private let socketMgr    = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        socketMgr.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSocketConnected)

        // QR görselini currentRoom PIN'i değiştikçe arka planda üret.
        $currentRoom
            .map { $0?.pinCode }
            .removeDuplicates()
            .receive(on: DispatchQueue.global(qos: .userInitiated))
            .map { pin -> UIImage? in
                guard let pin else { return nil }
                return Self.generateQRImage(for: pin)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$qrCodeImage)

        wireSocketCallbacks()
    }

    // MARK: - Oda Oluşturma (Anlık — bütçe/mesafe yok, lobi içinde kategori seçilir)

    func createRoom() async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil

        do {
            let payload = CreateRoomPayload(name: "Grup Odası", categories: [])
            let room    = try await network.createRoom(payload: payload)
            currentRoom    = room
            participantIds = [room.hostId]
            socketMgr.joinRoom(roomId: room.roomId)
        } catch let err as NetworkError {
            errorMessage = err.localizedDescription
        } catch {
            errorMessage = "Beklenmeyen bir hata oluştu."
        }

        isLoading = false
    }

    // MARK: - Odaya Katılma (PIN ile)

    func joinRoom(pinCode: String) async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil

        do {
            let payload = JoinRoomPayload(qrCode: pinCode)
            let room    = try await network.joinRoom(payload: payload)
            currentRoom = room
            socketMgr.joinRoom(roomId: room.roomId)
        } catch let err as NetworkError {
            errorMessage = err.localizedDescription
        } catch {
            errorMessage = "Beklenmeyen bir hata oluştu."
        }

        isLoading = false
    }

    // MARK: - Odadan Ayrılma

    func leaveCurrentRoom() {
        guard let room = currentRoom else { return }
        socketMgr.leaveRoom(roomId: room.roomId)

        deckExhaustedTask?.cancel()
        deckExhaustedTask   = nil

        currentRoom         = nil
        participantIds      = []
        votes               = [:]
        matchedRestaurantId = nil
        roomRestaurants     = []
        votedRestaurantIds  = []
        pendingVotes        = []
        isDeckExhausted     = false
        isVotingStarted     = false
        selectedCategories  = []
        errorMessage        = nil
    }

    // MARK: - Restoran Havuzu (Faz 4)

    func fetchRoomRestaurants() async {
        guard let room = currentRoom else { return }
        do {
            roomRestaurants = try await network.fetchRoomRestaurants(roomId: room.roomId)
        } catch {
            errorMessage = "Restoran listesi alınamadı. Lütfen tekrar deneyin."
        }
    }

    // MARK: - Lobi Kategori ve Oylama Başlatma

    /// Kullanıcının seçtiği kategorileri sunucuya bildirir.
    func submitCategories() {
        guard let room = currentRoom else { return }
        socketMgr.submitCategories(roomId: room.roomId, categories: Array(selectedCategories))
    }

    /// Yalnızca host çağırabilir. Sunucu voting_started ile restoranları gönderir.
    func startVoting() {
        guard let room = currentRoom else { return }
        socketMgr.startVoting(roomId: room.roomId) { [weak self] success, errorMsg in
            guard let self else { return }
            if !success {
                self.errorMessage = errorMsg ?? "Oylama başlatılamadı."
            }
        }
    }

    // MARK: - Oylama

    func submitVote(restaurantId: String, isApproved: Bool) {
        guard let room = currentRoom else { return }
        guard !votedRestaurantIds.contains(restaurantId),
              !pendingVotes.contains(restaurantId) else { return }

        pendingVotes.insert(restaurantId)

        socketMgr.submitVote(
            roomId:       room.roomId,
            restaurantId: restaurantId,
            isApproved:   isApproved
        ) { [weak self] success in
            guard let self else { return }
            self.pendingVotes.remove(restaurantId)
            if success {
                self.votedRestaurantIds.insert(restaurantId)
            } else {
                self.errorMessage = "Oy gönderilemedi. Lütfen tekrar deneyin."
            }
        }
    }

    // MARK: - Uygulama Yaşam Döngüsü

    func appDidEnterBackground() {
        socketMgr.disconnect()
    }

    func appDidBecomeActive() {
        // Token yoksa socket bağlantısı açma
        let token = KeychainHelper.load(forKey: AppConstants.keychainTokenKey) ?? ""
        guard !token.isEmpty else { return }
        guard let roomId = currentRoom?.roomId else { return }
        socketMgr.joinRoom(roomId: roomId)
    }

    // MARK: - QR Kod Üretimi

    static func generateQRImage(for pin: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(pin.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let ciOutput = filter.outputImage else { return nil }
        let scaled = ciOutput.transformed(by: CGAffineTransform(scaleX: 12, y: 12))

        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Private

    private func wireSocketCallbacks() {
        socketMgr.onMemberJoined = { [weak self] userId in
            guard let self else { return }
            if !self.participantIds.contains(userId) {
                self.participantIds.append(userId)
            }
        }
        socketMgr.onMemberLeft = { [weak self] userId in
            self?.participantIds.removeAll { $0 == userId }
        }
        socketMgr.onVoteUpdate = { [weak self] restaurantId, approvedBy, rejectedBy in
            guard let self else { return }
            self.votes[restaurantId] = RestaurantVote(
                restaurantId: restaurantId,
                approvedBy:   approvedBy,
                rejectedBy:   rejectedBy
            )
        }
        socketMgr.onMatchFound = { [weak self] restaurantId in
            self?.matchedRestaurantId = restaurantId
        }

        socketMgr.onDeckExhausted = { [weak self] in
            guard let self else { return }
            self.isDeckExhausted = true

            self.deckExhaustedTask?.cancel()
            self.deckExhaustedTask = Task { [weak self] in
                defer { Task { @MainActor in self?.deckExhaustedTask = nil } }
                do {
                    try await Task.sleep(for: .seconds(2))
                    try Task.checkCancellation()
                } catch {
                    return
                }
                guard let self else { return }
                self.votes              = [:]
                self.votedRestaurantIds = []
                self.pendingVotes       = []
                self.roomRestaurants    = []
                await self.fetchRoomRestaurants()
                self.isDeckExhausted = false
            }
        }

        socketMgr.onSyncRoomState = { [weak self] rawVotes, matchedIds, _, myVotedIds in
            guard let self else { return }
            var synced: [String: RestaurantVote] = [:]
            for (restaurantId, voteData) in rawVotes {
                synced[restaurantId] = RestaurantVote(
                    restaurantId: restaurantId,
                    approvedBy:   voteData["approved"] ?? [],
                    rejectedBy:   voteData["rejected"] ?? []
                )
            }
            self.votes = synced
            // my_voted_ids geliyorsa votedRestaurantIds'i senkronize et
            self.votedRestaurantIds = Set(myVotedIds)
            if let lastMatch = matchedIds.last {
                self.matchedRestaurantId = lastMatch
            }
        }

        socketMgr.onJoinRoomRejected = { [weak self] reason in
            self?.errorMessage = reason
        }

        socketMgr.onConnectionFailed = { [weak self] reason in
            self?.errorMessage = reason
        }

        socketMgr.onVotingStarted = { [weak self] restaurants in
            guard let self else { return }
            self.roomRestaurants = restaurants
            self.isVotingStarted = true
        }
    }
}
