//
//  LoginView.swift
//  MenuLo
//
//  MenuLo/Views/Auth/LoginView.swift
//
//  Kullanıcı giriş ekranı. Müşteri / İşletme sekmeleri ile ayrılmıştır.
//  Tasarımı RegisterView'daki segmented picker ile birebir tutarlıdır.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var selectedTab: Int = 0   // 0 = Müşteri, 1 = İşletme
    @State private var showForgotSheet = false

    private var selectedUserType: UserType {
        selectedTab == 1 ? .business : .customer
    }

    private var primaryButtonTitle: String {
        selectedTab == 1 ? "İşletme Girişi" : "Giriş Yap"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.xl) {

                    // MARK: - Logo / Başlık
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

                    // MARK: - Giriş Tipi Seçici (RegisterView ile birebir aynı stil)
                    HStack(spacing: 0) {
                        LoginTabSegment(
                            title: "Müşteri",
                            iconName: "person.fill",
                            isSelected: selectedTab == 0
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 0
                                authVM.clearError()
                            }
                        }

                        LoginTabSegment(
                            title: "İşletme",
                            iconName: "building.2.fill",
                            isSelected: selectedTab == 1
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedTab = 1
                                authVM.clearError()
                            }
                        }
                    }
                    .padding(4)
                    .background(MenuLoTheme.Colors.divider.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large))
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // MARK: - Form
                    VStack(spacing: MenuLoTheme.Spacing.md) {
                        CustomTextField(placeholder: "E-posta", iconName: "envelope.fill", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        CustomTextField(placeholder: "Şifre", iconName: "lock.fill", text: $password, isSecure: true)

                        // Şifremi Unuttum — minimal alt-sağ link
                        HStack {
                            Spacer()
                            Button("Şifremi Unuttum") {
                                showForgotSheet = true
                            }
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // MARK: - Hata Mesajı
                    if authVM.showError && !authVM.errorMessage.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text(authVM.errorMessage)
                                .font(MenuLoTheme.Fonts.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .transition(.opacity)
                    }

                    // MARK: - Giriş Butonu (dinamik metin)
                    PrimaryButton(title: primaryButtonTitle, isLoading: authVM.isLoading) {
                        authVM.login(email: email, password: password, userType: selectedUserType)
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // MARK: - Kayıt Yönlendirme
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
                    .padding(.top, MenuLoTheme.Spacing.sm)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onDisappear {
                authVM.clearError()
            }
            .sheet(isPresented: $showForgotSheet) {
                ForgotPasswordSheet()
            }
        }
    }
}

// MARK: - Tab Segment (RegisterView'daki TabSegment ile birebir aynı stil)
private struct LoginTabSegment: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.footnote)
                Text(title)
                    .font(MenuLoTheme.Fonts.button)
            }
            .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MenuLoTheme.Spacing.sm)
            .background(
                isSelected
                    ? MenuLoTheme.Colors.primary
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium - 2))
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
