//
//  ReviewViewModel.swift
//  MenuLo
//
//  Restoran yorum listesi ve form gönderimi için tek view model.
//  RestaurantDetailView'daki "Yorumlar" bölümünü besler ve aynı zamanda
//  AddReviewSheet'in form state'ini tutar — böylece sheet kapanıp açıldığında
//  taslak korunur ve gönderim sonrası liste anında güncellenir.
//

import Foundation
import SwiftUI

@MainActor
final class ReviewViewModel: ObservableObject {

    // MARK: - Liste durumu
    @Published private(set) var reviews: [AppReview] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Form (taslak) durumu — AddReviewSheet kullanır
    @Published var draftContent: String = ""
    @Published var draftTaste: Int? = nil
    @Published var draftService: Int? = nil
    @Published var draftAttitude: Int? = nil
    @Published private(set) var isSubmitting = false

    /// DiscoverViewModel'deki idempotent fetch pattern'iyle aynı: aynı restoran
    /// için tekrarlı çağrılarda ağa gitme.
    private var loadedRestaurantId: Int?

    func fetchReviews(restaurantId: Int, forceRefresh: Bool = false) async {
        if isLoading { return }
        if !forceRefresh,
           loadedRestaurantId == restaurantId,
           !reviews.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil
        do {
            let list = try await NetworkManager.shared.fetchReviews(restaurantId: restaurantId)
            self.reviews = list
            self.loadedRestaurantId = restaurantId
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Form state'inden payload kurar ve gönderir. Başarılıysa listeye prepend eder ve
    /// taslağı sıfırlar; çağıran sheet'ini güvenle kapatabilir.
    @discardableResult
    func submitDraft(restaurantId: Int) async -> Bool {
        guard !isSubmitting else { return false }

        let trimmed = draftContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasRating = draftTaste != nil || draftService != nil || draftAttitude != nil
        if trimmed.isEmpty && !hasRating {
            errorMessage = "Yorum metni veya en az bir puan girmelisiniz."
            return false
        }

        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        let payload = ReviewSubmitPayload(
            content:        trimmed.isEmpty ? nil : trimmed,
            ratingTaste:    draftTaste,
            ratingService:  draftService,
            ratingAttitude: draftAttitude
        )
        do {
            let created = try await NetworkManager.shared.submitReview(
                restaurantId: restaurantId,
                payload: payload
            )
            reviews.insert(created, at: 0)
            resetDraft()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func resetDraft() {
        draftContent = ""
        draftTaste = nil
        draftService = nil
        draftAttitude = nil
    }
}
