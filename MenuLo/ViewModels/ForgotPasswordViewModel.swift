//
//  ForgotPasswordViewModel.swift
//  MenuLo
//
//  Şifremi unuttum akışı. Sheet'in form state'ini ve API çağrısını tutar.
//  Backend her zaman 200 + generic mesaj döner — kullanıcı varlığı ifşa edilmez,
//  bu yüzden UI başarılı yanıtta her email için aynı bilgiyi gösterir.
//

import Foundation
import SwiftUI

@MainActor
final class ForgotPasswordViewModel: ObservableObject {

    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published private(set) var didSend: Bool = false

    /// Basit email regex — ASCII odaklı, sunucu tarafı son sözü söyler.
    private let emailRegex = try? NSRegularExpression(pattern: "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")

    func sendReset() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "E-posta adresi boş bırakılamaz."
            return
        }
        if let r = emailRegex,
           r.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.count)) == nil {
            errorMessage = "Geçerli bir e-posta adresi giriniz."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await NetworkManager.shared.forgotPassword(email: trimmed)
            didSend = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        email = ""
        errorMessage = nil
        didSend = false
    }
}
