//
//  ChangePasswordViewModel.swift
//  MenuLo
//
//  Authenticated kullanıcı için şifre değiştirme akışı.
//  Form: mevcut şifre, yeni şifre, yeni şifre tekrar.
//

import Foundation
import SwiftUI

@MainActor
final class ChangePasswordViewModel: ObservableObject {

    @Published var oldPassword:        String = ""
    @Published var newPassword:        String = ""
    @Published var newPasswordConfirm: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var didSucceed: Bool = false

    private let minPasswordLength = 8

    /// Form geçerli mi? UI Save butonunu disable etmek için izler.
    var isFormValid: Bool {
        !oldPassword.isEmpty &&
        newPassword.count >= minPasswordLength &&
        newPassword == newPasswordConfirm &&
        oldPassword != newPassword
    }

    func change() async {
        // Client-side sanity checks — sunucu son sözü söyler ama kullanıcıya
        // hızlı feedback verelim
        guard !oldPassword.isEmpty else {
            errorMessage = "Mevcut şifrenizi giriniz."
            return
        }
        guard newPassword.count >= minPasswordLength else {
            errorMessage = "Yeni şifre en az \(minPasswordLength) karakter olmalıdır."
            return
        }
        guard newPassword == newPasswordConfirm else {
            errorMessage = "Yeni şifreler eşleşmiyor."
            return
        }
        guard oldPassword != newPassword else {
            errorMessage = "Yeni şifre eski şifre ile aynı olamaz."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await NetworkManager.shared.changePassword(
                oldPassword: oldPassword,
                newPassword: newPassword
            )
            didSucceed = true
            // Başarı sonrası form alanlarını temizle
            oldPassword = ""
            newPassword = ""
            newPasswordConfirm = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        oldPassword = ""
        newPassword = ""
        newPasswordConfirm = ""
        errorMessage = nil
        didSucceed = false
    }
}
