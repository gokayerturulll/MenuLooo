//
//  Constants.swift
//  MenuLo
//
//  Uygulama genelinde kullanılan sabit değerler.
//  API adresleri, zaman aşımı süreleri ve diğer konfigürasyon değerleri burada tanımlanır.
//

import Foundation

/// Uygulama genelinde kullanılan sabitler.
enum AppConstants {
    
    // MARK: - API Konfigürasyonu
    
    /// Backend sunucu base URL'i.
    /// Geliştirme aşamasında localhost, yayında gerçek sunucu adresi kullanılır.
    static let apiBaseURL = "http://localhost:3000/api"
    
    /// Socket.io sunucu URL'i (Karar Odaları ve Green Menu bildirimleri için).
    static let socketURL = "http://localhost:3000"
    
    /// API istek zaman aşımı süresi (saniye)
    static let requestTimeout: TimeInterval = 30
    
    // MARK: - Uygulama Bilgileri
    
    /// Uygulama versiyonu
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    
    /// Build numarası
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Keychain Anahtarları
    
    /// Kullanıcı erişim token'ının Keychain'de saklanacağı anahtar
    static let keychainTokenKey = "com.menulo.authToken"
    
    /// Kullanıcı refresh token'ının Keychain'de saklanacağı anahtar
    static let keychainRefreshTokenKey = "com.menulo.refreshToken"
    
    // MARK: - UserDefaults Anahtarları
    
    /// Kullanıcının ilk kez uygulamayı açıp açmadığını takip eden anahtar
    static let hasLaunchedBeforeKey = "hasLaunchedBefore"
    
    /// Kullanıcının tercih ettiği tema modu
    static let preferredThemeKey = "preferredTheme"
}
