import Foundation

enum AppConstants {

    // MARK: - API Konfigürasyonu
    // DEBUG: localhost üzerinden geliştirme.
    // RELEASE: API_BASE_URL Info.plist anahtarı zorunlu — xcconfig ile inject edilir.
    //          Placeholder veya boş değer fatalError ile derhal çöktürür — sessiz
    //          başarısızlık yerine yanlış DNS'e gitme riski engellenir.
    #if DEBUG
    /// Build Phase script ngrok URL'ini NgrokURL.swift dosyasına yazar.
    /// Ngrok yoksa localhost'a düşer.
    static let apiBaseURL = NgrokConfig.baseURL
    #else
    static let apiBaseURL: String = {
        let value = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("your-production-server"),
              trimmed.hasPrefix("https://") else {
            fatalError("API_BASE_URL Info.plist anahtarı release build için zorunludur (https:// ile başlayan gerçek bir adres).")
        }
        return trimmed
    }()
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
