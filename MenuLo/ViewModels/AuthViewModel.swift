//
//  AuthViewModel.swift
//  MenuLo
//
//  Kimlik doğrulama iş mantığını yöneten ViewModel.
//
//  ## MVVM Mimarisi — ViewModel Nedir?
//  MVVM (Model-View-ViewModel) deseninde ViewModel, View ile Model arasındaki köprüdür.
//  - **Model**: Ham veri (User struct'ı gibi)
//  - **View**: Kullanıcının gördüğü arayüz (LoginView gibi)
//  - **ViewModel**: İş mantığı. API çağrısı yapar, veriyi işler, View'a sunar.
//
//  SwiftUI'da ViewModel, `ObservableObject` protokolünü benimser.
//  `@Published` ile işaretlenen property'ler değiştiğinde, bu ViewModel'i
//  dinleyen tüm View'lar otomatik olarak güncellenir (reaktif programlama).
//

import Foundation
import SwiftUI

/// Kimlik doğrulama durumunu ve kullanıcı oturumunu yöneten ViewModel.
///
/// Bu class, uygulamanın her yerinden erişilebilir olması için
/// `MenuLoApp.swift`'te `@StateObject` olarak oluşturulur ve
/// `.environmentObject()` ile tüm View hiyerarşisine enjekte edilir.
///
/// Kullanım (View tarafında):
/// ```swift
/// struct LoginView: View {
///     @EnvironmentObject var authVM: AuthViewModel
///     // authVM.login(email:password:) şeklinde çağrılır
/// }
/// ```
/// Login/Register sonrası kullanıcı tipine göre yönlendirilecek kök ekran.
enum RootDestination {
    case login          // Henüz giriş yapılmadı → LoginView
    case customerHome   // Müşteri → MainTabView (Keşfet açılır)
    case businessHome   // İşletme → MenuManagerView paneli
}

@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties (View'ı Güncelleyen Değerler)

    /// Kullanıcı giriş yapmış mı? `true` ise MainTabView, `false` ise LoginView gösterilir.
    @Published var isAuthenticated: Bool = false

    /// Şu an giriş yapmış olan kullanıcının bilgileri. Giriş yapılmamışsa `nil`.
    @Published var currentUser: User? = nil

    /// Giriş/kayıt işlemi devam ederken `true` olur. Loading spinner göstermek için.
    @Published var isLoading: Bool = false

    /// Hata mesajı. Boş string ise hata yok demektir. Alert göstermek için kullanılır.
    @Published var errorMessage: String = ""

    /// Hata alert'inin gösterilip gösterilmediğini kontrol eder.
    @Published var showError: Bool = false

    /// Routing helper — ContentView bunu izleyerek doğru kök ekrana yönlendirir.
    var rootDestination: RootDestination {
        guard isAuthenticated, let user = currentUser else { return .login }
        return user.userType == .business ? .businessHome : .customerHome
    }
    
    // MARK: - Giriş (Login)
    
    /// E-posta ve şifre ile giriş yapar.
    ///
    /// - Parameters:
    ///   - email: Kullanıcının e-posta adresi
    ///   - password: Kullanıcının şifresi
    ///   - userType: Login ekranında seçilen tip (Customer / Business).
    ///     Backend'den dönen gerçek role ile karşılaştırılır; uyuşmazsa
    ///     kullanıcıya doğru sekmeden girmesi gerektiği bildirilir.
    func login(email: String, password: String, userType: UserType) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "E-posta ve şifre alanları boş bırakılamaz."
            self.showError = true
            return
        }

        isLoading = true

        Task {
            do {
                let response = try await NetworkManager.shared.login(email: email, password: password)
                if response.success, let user = response.user {
                    // Seçilen sekme ile gerçek hesap rolü uyumlu mu?
                    guard user.userType == userType else {
                        let expected = user.userType == .business ? "İşletme" : "Müşteri"
                        self.errorMessage = "Bu hesap \(expected) olarak kayıtlı. Lütfen \(expected) sekmesinden giriş yapın."
                        self.showError = true
                        self.isLoading = false
                        return
                    }

                    if let token = response.token {
                        KeychainHelper.save(token, forKey: AppConstants.keychainTokenKey)
                    }
                    self.currentUser = user
                    self.isAuthenticated = true
                } else {
                    self.errorMessage = response.message ?? "Giriş başarısız."
                    self.showError = true
                }
            } catch {
                self.errorMessage = "Sunucu hatası: \(error.localizedDescription)"
                self.showError = true
            }
            self.isLoading = false
        }
    }

    // MARK: - Kayıt (Register)

    func register(name: String, email: String, password: String, userType: UserType) {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Tüm alanlar doldurulmalıdır."
            self.showError = true
            return
        }
        isLoading = true

        let role = userType == .business ? "Owner" : "Customer"
        
        Task {
            do {
                let response = try await NetworkManager.shared.register(name: name, email: email, password: password, role: role)
                
                if response.success {
                    // Kayıt başarılı, arka planda hemen login yapalım:
                    let loginResp = try await NetworkManager.shared.login(email: email, password: password)
                    if loginResp.success, let user = loginResp.user {
                        if let token = loginResp.token {
                            KeychainHelper.save(token, forKey: AppConstants.keychainTokenKey)
                        }
                        self.currentUser = user
                        self.isAuthenticated = true
                    } else {
                        self.errorMessage = "Kayıt başarılı ancak giriş yapılamadı. Lütfen giriş sayfasına dönün."
                        self.showError = true
                    }
                } else {
                    self.errorMessage = response.message ?? "Kayıt işlemi başarısız."
                    self.showError = true
                }
            } catch {
                self.errorMessage = "Sunucu hatası: \(error.localizedDescription)"
                self.showError = true
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Session Expiry Observer

    private var sessionObserver: NSObjectProtocol?

    /// 401 NotificationCenter mesajını dinleyerek otomatik çıkış yapar.
    func startObservingSessionExpiry() {
        sessionObserver = NotificationCenter.default.addObserver(
            forName: .userSessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Closure non-isolated; @MainActor logout()'a güvenli sıçra
            Task { @MainActor in self?.logout() }
        }
    }

    deinit {
        if let obs = sessionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Çıkış (Logout)

    /// Kullanıcı oturumunu sonlandırır.
    func logout() {
        KeychainHelper.delete(forKey: AppConstants.keychainTokenKey)
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Hata Temizleme
    
    /// Hata mesajını temizler.
    func clearError() {
        errorMessage = ""
        showError = false
    }
}
