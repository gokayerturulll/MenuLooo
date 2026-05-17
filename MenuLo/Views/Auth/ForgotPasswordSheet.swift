//
//  ForgotPasswordSheet.swift
//  MenuLo
//
//  LoginView'in altından açılan minimal sheet. Email gir → Gönder → başarılıysa
//  generic "kontrol et" ekranı.
//

import SwiftUI

struct ForgotPasswordSheet: View {

    @StateObject private var viewModel = ForgotPasswordViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MenuLoTheme.Spacing.lg) {

                if viewModel.didSend {
                    // Success state — generic mesaj (kullanıcı varlığı ifşa edilmez)
                    successState
                } else {
                    formState
                }

                Spacer()
            }
            .padding(MenuLoTheme.Spacing.lg)
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .navigationTitle("Şifremi Unuttum")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") {
                        viewModel.reset()
                        dismiss()
                    }
                    .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Form

    private var formState: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {

            VStack(spacing: MenuLoTheme.Spacing.sm) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 56))
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .padding(.bottom, MenuLoTheme.Spacing.sm)

                Text("E-posta adresinizi girin")
                    .font(MenuLoTheme.Fonts.subtitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                Text("Hesabınıza bağlı e-postaya şifre sıfırlama bağlantısı göndereceğiz.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, MenuLoTheme.Spacing.xl)

            CustomTextField(
                placeholder: "E-posta",
                iconName: "envelope.fill",
                text: $viewModel.email
            )
            .keyboardType(.emailAddress)
            .autocapitalization(.none)

            if let err = viewModel.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(err)
                }
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.red)
                .transition(.opacity)
            }

            PrimaryButton(title: "Gönder", isLoading: viewModel.isLoading) {
                Task { await viewModel.sendReset() }
            }
            .padding(.top, MenuLoTheme.Spacing.sm)
        }
    }

    // MARK: - Success

    private var successState: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundColor(MenuLoTheme.Colors.success)
                .padding(.top, MenuLoTheme.Spacing.xxl)

            Text("E-postanı kontrol et")
                .font(MenuLoTheme.Fonts.title)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)

            Text("Eğer bu e-posta kayıtlıysa, şifre sıfırlama bağlantısını içeren bir e-posta gönderdik. Spam klasörünü de kontrol etmeyi unutma.")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            PrimaryButton(title: "Giriş Ekranına Dön") {
                viewModel.reset()
                dismiss()
            }
            .padding(.top, MenuLoTheme.Spacing.lg)
        }
    }
}

#Preview {
    ForgotPasswordSheet()
}
