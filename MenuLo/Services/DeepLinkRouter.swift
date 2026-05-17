import Foundation

// MARK: - DeepLinkDestination

enum DeepLinkDestination: Equatable {
    case room(pinCode: String)
    case restaurant(id: Int)
}

// MARK: - Notification.Name

extension Notification.Name {
    static let menuloDeepLinkReceived = Notification.Name("menuloDeepLinkReceived")
}

// MARK: - DeepLinkRouter

/// onOpenURL ve bildirim tıklamalarından gelen menulo:// URL'lerini parse eder,
/// SwiftUI hiyerarşisine @EnvironmentObject aracılığıyla yönlendirme iletir.
///
/// Desteklenen formatlar:
///   menulo://room/<PIN_CODE>         → RoomListView'da odaya katıl
///   menulo://restaurant/<ID>         → RestaurantDetailView'ı aç
@MainActor
final class DeepLinkRouter: ObservableObject {

    @Published var pending: DeepLinkDestination?

    private var notificationObserver: NSObjectProtocol?

    init() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .menuloDeepLinkReceived,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            if let url = notif.object as? URL {
                self?.handle(url: url)
            }
        }
    }

    deinit {
        if let obs = notificationObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func handle(url: URL) {
        guard url.scheme?.lowercased() == "menulo" else { return }
        let host  = url.host?.lowercased() ?? ""
        let parts = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "room":
            if let code = parts.first, !code.isEmpty {
                pending = .room(pinCode: code.uppercased())
            }
        case "restaurant":
            if let idStr = parts.first, let id = Int(idStr) {
                pending = .restaurant(id: id)
            }
        default:
            break
        }
    }
}
