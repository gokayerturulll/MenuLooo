import Foundation
import UserNotifications
import UIKit

// MARK: - NotificationManager
// APNs bildirim izni, cihaz token kaydı ve bildirim yanıtlarını yönetir.

final class NotificationManager: NSObject {

    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - İzin İsteme

    /// Kullanıcıdan bildirim izni ister; izin verilince APNs token kaydını başlatır.
    /// Kimlik doğrulama sonrası MainTabView.onAppear içinden çağrılır.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            if let error {
                print("[APNs] İzin hatası:", error.localizedDescription)
                return
            }
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    // MARK: - Token Kaydı

    /// AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken tarafından çağrılır.
    func onDeviceTokenReceived(_ token: String) {
        Task {
            try? await NetworkManager.shared.registerDeviceToken(token)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {

    /// Uygulama ön plandayken gelen bildirimi banner + ses ile göster.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler handler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handler([.banner, .sound, .badge])
    }

    /// Kullanıcı bildirime tıklayınca payload'daki deep_link ile yönlendir.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler handler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let deepLinkStr = userInfo["deep_link"] as? String,
           let url = URL(string: deepLinkStr) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .menuloDeepLinkReceived, object: url)
            }
        }
        handler()
    }
}
