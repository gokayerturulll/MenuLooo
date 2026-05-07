//
//  MyBusinessViewModel.swift
//  MenuLo
//
//  MenuLo/ViewModels/MyBusinessViewModel.swift
//
//  MyBusinessView için iş mantığı: detay yükleme + güncelleme.
//  Form state'leri @Published'larda tutulur — view doğrudan binding'le yazar/okur.
//

import Foundation
import SwiftUI

@MainActor
final class MyBusinessViewModel: ObservableObject {

    // MARK: - Form alanları (View doğrudan binding'le bunlara yazar)
    @Published var businessName: String = ""
    @Published var address:      String = ""
    @Published var phone:        String = ""
    @Published var website:      String = ""
    @Published var description:  String = ""
    @Published var cuisineType:  String = ""
    @Published var latitude:     Double = 0
    @Published var longitude:    Double = 0
    @Published var workingHours: WorkingHours = .default

    // MARK: - Network state
    @Published var isLoading: Bool = false
    @Published var isSubmitting: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false
    @Published var saveSucceeded: Bool = false

    let restaurantId: Int

    /// İlk başarılı load tamamlandı mı — UI buna göre placeholder vs gerçek alanları gösterir.
    @Published private(set) var hasLoaded: Bool = false

    init(restaurantId: Int) {
        self.restaurantId = restaurantId
    }

    // MARK: - Load
    func load(force: Bool = false) async {
        if isLoading { return }
        if hasLoaded && !force { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let detail = try await NetworkManager.shared.fetchRestaurantDetails(restaurantId: restaurantId)
            apply(detail)
            self.hasLoaded = true
        } catch {
            present(error)
        }
    }

    // MARK: - Save
    @discardableResult
    func save() async -> Bool {
        if isSubmitting { return false }
        isSubmitting = true
        defer { isSubmitting = false }

        let payload = RestaurantUpdatePayload(
            businessName: trimmedOrNil(businessName),
            address:      trimmedOrNil(address),
            phone:        trimmedOrNil(phone),
            website:      trimmedOrNil(website),
            description:  trimmedOrNil(description),
            cuisineType:  trimmedOrNil(cuisineType),
            latitude:     latitude,
            longitude:    longitude,
            workingHours: workingHours
        )

        do {
            let updated = try await NetworkManager.shared.updateRestaurantDetails(
                restaurantId: restaurantId,
                payload: payload
            )
            apply(updated)
            self.saveSucceeded = true
            return true
        } catch {
            present(error)
            return false
        }
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func clearSaveSuccess() {
        saveSucceeded = false
    }

    // MARK: - Helpers

    private func apply(_ detail: RestaurantDetail) {
        self.businessName = detail.businessName
        self.address      = detail.address      ?? ""
        self.phone        = detail.phone        ?? ""
        self.website      = detail.website      ?? ""
        self.description  = detail.description  ?? ""
        self.cuisineType  = detail.cuisineType  ?? ""
        self.latitude     = detail.latitude     ?? 0
        self.longitude    = detail.longitude    ?? 0
        self.workingHours = detail.workingHours ?? .default
    }

    private func trimmedOrNil(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private func present(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.showError = true
    }
}
