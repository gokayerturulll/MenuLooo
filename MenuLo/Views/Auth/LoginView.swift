//
//  LoginView.swift
//  MenuLo
//
//  Kullanıcı giriş ekranı.
//  Bu aşamada temel form yapısı ve AuthViewModel entegrasyonu mevcut.
//  İlerleyen aşamalarda UI detaylandırılacak, FaceID ve kayıt ekranı eklenecek.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    // MARK: - Form State
    
    /// Kullanıcının girdiği e-posta adresi
    @State private var email: String = ""
    
    /// Kullanıcının girdiği şifre
    @State private var password: String = ""
    
    /// Şifrenin görünür olup olmadığı
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Arka plan
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()
                
                VStack(spacing: MenuLoTheme.Spacing.lg) {
                    
                    Spacer()
                    
                    // MARK: - Logo & Başlık
                    logoSection
                    
                    Spacer()
                        .frame(height: MenuLoTheme.Spacing.xl)
                    
                    // MARK: - Giriş Formu
                    formSection
                    
                    // MARK: - Giriş Butonu
                    loginButton
                    
                    // MARK: - Kayıt Yönlendirme
                    registerLink
                    
                    Spacer()
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
            }
        }
        // Hata Alert'i
        .alert("Hata", isPresented: $authViewModel.showError) {
            Button("Tamam", role: .cancel) {
                authViewModel.clearError()
            }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    // MARK: - Alt Bileşenler (Sub-Views)
    
    /// Logo ve karşılama mesajı
    private var logoSection: some View {
        VStack(spacing: MenuLoTheme.Spacing.sm) {
            // Uygulama ikonu placeholder
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(MenuLoTheme.Colors.primary)
                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 10, y: 5)
            
            Text("MenuLo")
                .font(MenuLoTheme.Fonts.largeTitle)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            
            Text("Lezzetin dijital rehberi")
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
    }
    
    /// E-posta ve şifre giriş alanları
    private var formSection: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            // E-posta Alanı
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                TextField("E-posta adresi", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .font(MenuLoTheme.Fonts.body)
            }
            .padding()
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
            
            // Şifre Alanı
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .frame(width: 24)
                
                if isPasswordVisible {
                    TextField("Şifre", text: $password)
                        .font(MenuLoTheme.Fonts.body)
                } else {
                    SecureField("Şifre", text: $password)
                        .font(MenuLoTheme.Fonts.body)
                }
                
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
            }
            .padding()
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
        }
    }
    
    /// Giriş yap butonu
    private var loginButton: some View {
        Button {
            authViewModel.login(email: email, password: password)
        } label: {
            HStack {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Giriş Yap")
                        .font(MenuLoTheme.Fonts.button)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(MenuLoTheme.Colors.primary)
            .cornerRadius(MenuLoTheme.CornerRadius.pill)
            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(authViewModel.isLoading)
    }
    
    /// Kayıt ol yönlendirmesi
    private var registerLink: some View {
        HStack {
            Text("Hesabın yok mu?")
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
            
            Button("Kayıt Ol") {
                // TODO: Aşama 2'de RegisterView'a navigasyon
            }
            .font(MenuLoTheme.Fonts.caption)
            .fontWeight(.semibold)
            .foregroundColor(MenuLoTheme.Colors.primary)
        }
    }
}

// MARK: - SwiftUI Preview

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
