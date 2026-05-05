//
//  RegisterView.swift
//  MenuLo
//
//  MenuLo/Views/Auth/RegisterView.swift
//
//  Yeni kullanıcı kayıt ekranı.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isBusiness = false // Kullanıcı işletme sahibi mi?
    
    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            
            VStack(spacing: MenuLoTheme.Spacing.sm) {
                Text("Aramıza Katıl")
                    .font(MenuLoTheme.Fonts.largeTitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                
                Text("Müşteri veya işletme hesabını hemen oluştur.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .padding(.top, MenuLoTheme.Spacing.lg)
            
            // Form Alanı
            VStack(spacing: MenuLoTheme.Spacing.md) {
                CustomTextField(placeholder: "Ad Soyad", iconName: "person.fill", text: $name)
                
                CustomTextField(placeholder: "E-posta", iconName: "envelope.fill", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                CustomTextField(placeholder: "Şifre", iconName: "lock.fill", text: $password, isSecure: true)
                
                // İşletme hesabı seçeneği
                Toggle(isOn: $isBusiness) {
                    Text("Restoran Sahibi misiniz?")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                }
                .tint(MenuLoTheme.Colors.primary)
                .padding()
                .background(MenuLoTheme.Colors.cardBackground)
                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            
            // Kayıt Butonu
            PrimaryButton(title: "Hesap Oluştur", isLoading: authVM.isLoading) {
                // authVM.register(name: name, email: email, password: password, isBusiness: isBusiness)
                print("Kayıt ol butonuna basıldı")
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            
            Spacer()
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
