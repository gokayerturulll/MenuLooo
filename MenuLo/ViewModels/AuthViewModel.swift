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
    
    // MARK: - Giriş (Login)
    
    /// E-posta ve şifre ile giriş yapar.
    ///
    /// Şimdilik gerçek API çağrısı yapılmıyor — placeholder implementasyon.
    /// İlerleyen aşamalarda `NetworkService` kullanılarak backend'e bağlanacak.
    ///
    /// - Parameters:
    ///   - email: Kullanıcının e-posta adresi
    ///   - password: Kullanıcının şifresi
    func login(email: String, password: String) {
        // Basit doğrulama
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "E-posta ve şifre alanları boş bırakılamaz."
            self.showError = true
            return
        }
        
        isLoading = true
        
        // Gerçek API çağrısı
        Task {
            do {
                let response = try await NetworkManager.shared.login(email: email, password: password)
                if response.success, let user = response.user {
                    // Token'ı AppStorage'a NetworkManager içinde kaydettirebiliriz veya burada UserDefaults ile yapabiliriz.
                    // NetworkManager'da @AppStorage("authToken") kullanıldığı için orada SwiftUI tarafında state güncellenecektir.
                    UserDefaults.standard.set(response.token, forKey: "authToken")
                    
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
    
    /// Yeni kullanıcı kaydı oluşturur.
    ///
    /// - Parameters:
    ///   - name: Kullanıcının adı
    ///   - email: E-posta adresi
    ///   - password: Şifre
    ///   - userType: Müşteri veya İşletme
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
                        UserDefaults.standard.set(loginResp.token, forKey: "authToken")
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
    
    // MARK: - Çıkış (Logout)
    
    /// Kullanıcı oturumunu sonlandırır.
    func logout() {
        // TODO: Keychain'den token silme (Aşama 2'de)
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
