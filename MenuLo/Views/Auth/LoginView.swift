//
//  LoginView.swift
//  MenuLo
//
//  MenuLo/Views/Auth/LoginView.swift
//
//  Kullanıcı giriş ekranı. CustomTextField ve PrimaryButton bileşenleri kullanılır.
//

import SwiftUI

struct LoginView: View {
    // ViewModel ile bağlantı
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var showRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: MenuLoTheme.Spacing.xl) {
                
                // 1. Logo / Başlık Alanı
                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    
                    Text("MenuLo'ya Hoş Geldin")
                        .font(MenuLoTheme.Fonts.largeTitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    
                    Text("Favori lezzetlerine bir adım daha yakınsın.")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, MenuLoTheme.Spacing.xxl)
                
                // 2. Form Alanı
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    CustomTextField(placeholder: "E-posta", iconName: "envelope.fill", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    CustomTextField(placeholder: "Şifre", iconName: "lock.fill", text: $password, isSecure: true)
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                
                // 3. Giriş Butonu
                PrimaryButton(title: "Giriş Yap", isLoading: authVM.isLoading) {
                    authVM.login(email: email, password: password)
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                
                Spacer()
                
                // 4. Kayıt Ol Yönlendirmesi
                HStack {
                    Text("Hesabın yok mu?")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    
                    NavigationLink(destination: RegisterView()) {
                        Text("Kayıt Ol")
                            .font(MenuLoTheme.Fonts.button)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                    }
                }
                .padding(.bottom, MenuLoTheme.Spacing.xl)
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            // Klavyenin üstteki içerikleri ezmemesi için ekranı yukarı kaydırır
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .alert("Giriş Başarısız", isPresented: $authVM.showError) {
            Button("Tamam", role: .cancel) {
                authVM.clearError()
            }
        } message: {
            Text(authVM.errorMessage)
        }
    }
}
