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
        
        // TODO: Gerçek API çağrısı (Aşama 2'de NetworkService ile)
        // Şimdilik sahte giriş simülasyonu:
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            // Demo kullanıcı ile giriş
            self.currentUser = User.example
            self.isAuthenticated = true
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
        
        // TODO: Gerçek API çağrısı (Aşama 2'de)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.currentUser = User(
                id: Int.random(in: 100...999),
                name: name,
                email: email,
                userType: userType
            )
            self.isAuthenticated = true
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
