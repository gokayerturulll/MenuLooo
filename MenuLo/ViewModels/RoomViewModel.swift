import Foundation
import Combine
import UIKit
import CoreImage

// MARK: - RoomViewModel

@MainActor
final class RoomViewModel: ObservableObject {

    // MARK: - UI State

    @Published var isLoading:       Bool    = false
    @Published var errorMessage:    String?
    @Published var currentRoom:     Room?
    @Published var participantIds:  [Int]   = []
    @Published var isSocketConnected: Bool  = false
    @Published private(set) var qrCodeImage: UIImage?

    private let network      = NetworkManager.shared
    private let socketMgr    = SocketManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        socketMgr.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isSocketConnected)

        // QR görselini currentRoom PIN'i değiştikçe otomatik üret
        $currentRoom
            .map { room -> UIImage? in
                guard let pin = room?.pinCode else { return nil }
                return Self.generateQRImage(for: pin)
            }
            .assign(to: &$qrCodeImage)

        wireSocketCallbacks()
    }

    // MARK: - Oda Oluşturma

    func createRoom(name: String, categories: [String], budget: Int, maxDistanceKm: Double) async {
        guard !isLoading else { return }
        isLoading    = true
        errorMessage = nil

        do {
            let payload = CreateRoomPayload(
                name:          name,
                categories:    categories,
                budget:        budget,
                maxDistanceKm: maxDistanceKm
            )
            let room = try await network.createRoom(payload: payload)
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
        currentRoom    = nil
        participantIds = []
    }

    // MARK: - Uygulama Yaşam Döngüsü (ScenePhase tarafından tetiklenir)

    func appDidEnterBackground() {
        socketMgr.disconnect()
    }

    func appDidBecomeActive() {
        guard let roomId = currentRoom?.roomId else { return }
        // connect() + joinRoom() — zaten aktifse no-op
        socketMgr.joinRoom(roomId: roomId)
    }

    // MARK: - QR Kod Üretimi

    /// CoreImage ile PIN'den kare ölçeklendirilmiş, taranabilir QR görsel üretir.
    /// `interpolation(.none)` ile gösterilmeli — piksel bozulmasını engeller.
    static func generateQRImage(for pin: String) -> UIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(Data(pin.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")   // orta hata düzeltme

        guard let ciOutput = filter.outputImage else { return nil }

        // 12x büyütme — net, bulanıksız piksel render için
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
    }
}
