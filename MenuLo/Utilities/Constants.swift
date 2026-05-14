import Foundation

enum AppConstants {

    // MARK: - API Konfigürasyonu
    // Gerçek cihaz testlerinde DEVICE_API_URL env var'ı veya xcconfig ile override edilebilir.
    // Derleme öncesi bu değeri aktif backend adresine güncelleyin.
    #if DEBUG
    static let apiBaseURL = "http://localhost:3000/api"
    #else
    static let apiBaseURL = ProcessInfo.processInfo.environment["API_BASE_URL"]
        ?? "https://your-production-server.com/api"
    #endif

    static let socketURL = apiBaseURL.replacingOccurrences(of: "/api", with: "")

    static let requestTimeout: TimeInterval = 30

    // MARK: - Uygulama Bilgileri
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Keychain Anahtarları
    static let keychainTokenKey = "com.menulo.authToken"
    static let keychainRefreshTokenKey = "com.menulo.refreshToken"

    // MARK: - UserDefaults Anahtarları
    static let hasLaunchedBeforeKey = "hasLaunchedBefore"
    static let preferredThemeKey = "preferredTheme"
}
