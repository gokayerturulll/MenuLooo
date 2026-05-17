//
//  ChangePasswordView.swift
//  MenuLo
//
//  Authenticated kullanıcı için şifre değiştirme ekranı.
//  ProfileView → Hesap Ayarları → "Şifreyi Değiştir" butonundan açılır.
//

import SwiftUI

struct ChangePasswordView: View {

    @StateObject private var viewModel = ChangePasswordViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showSuccessAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: MenuLoTheme.Spacing.lg) {

                // İkon + başlık
                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 56))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                        .padding(.top, MenuLoTheme.Spacing.xl)

                    Text("Şifreni güvenli tut")
                        .font(MenuLoTheme.Fonts.subtitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    Text("En az 8 karakter; harf, rakam ve sembol kullanmanı öneririz.")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }

                // Form
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    CustomTextField(
                        placeholder: "Mevcut Şifre",
                        iconName: "lock.fill",
                        text: $viewModel.oldPassword,
                        isSecure: true
                    )

                    CustomTextField(
                        placeholder: "Yeni Şifre",
                        iconName: "key.fill",
                        text: $viewModel.newPassword,
                        isSecure: true
                    )

                    CustomTextField(
                        placeholder: "Yeni Şifre (Tekrar)",
                        iconName: "key.fill",
                        text: $viewModel.newPasswordConfirm,
                        isSecure: true
                    )
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                // Hata mesajı
                if let err = viewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(err)
                    }
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .transition(.opacity)
                }

                PrimaryButton(title: "Şifreyi Güncelle", isLoading: viewModel.isLoading) {
                    Task {
                        await viewModel.change()
                        if viewModel.didSucceed {
                            showSuccessAlert = true
                        }
                    }
                }
                .opacity(viewModel.isFormValid ? 1.0 : 0.55)
                .disabled(!viewModel.isFormValid)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.sm)

                Spacer(minLength: MenuLoTheme.Spacing.xxl)
            }
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Şifre Değiştir")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Şifre güncellendi", isPresented: $showSuccessAlert) {
            Button("Tamam") { dismiss() }
        } message: {
            Text("Yeni şifrenle bir sonraki girişte oturum açabilirsin.")
        }
    }
}

#Preview {
    NavigationStack { ChangePasswordView() }
}
