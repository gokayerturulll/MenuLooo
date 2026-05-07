//
//  MenuManagerViewModel.swift
//  MenuLo
//
//  MenuLo/ViewModels/MenuManagerViewModel.swift
//
//  İşletme menüsü için CRUD iş mantığı. NetworkManager üzerinden async/await ile
//  çalışır, UI loading/error state'lerini yayınlar.
//

import Foundation
import SwiftUI

@MainActor
final class MenuManagerViewModel: ObservableObject {

    // MARK: - State
    @Published var items: [OwnerMenuItem] = []
    @Published var isLoading: Bool = false       // Liste yükleniyor (initial / refresh)
    @Published var isSubmitting: Bool = false    // Create / update / delete sürüyor
    @Published var errorMessage: String? = nil
    @Published var showError: Bool = false

    let restaurantId: Int

    init(restaurantId: Int) {
        self.restaurantId = restaurantId
    }

    // MARK: - Computed
    var totalCount: Int  { items.count }
    var activeCount: Int { items.filter { $0.isAvailable }.count }
    var greenCount: Int  { items.filter { $0.isGreenMenu }.count }

    var groupedByCategory: [(category: String, items: [OwnerMenuItem])] {
        Dictionary(grouping: items) { $0.category }
            .map { (category: $0.key, items: $0.value) }
            .sorted { $0.category < $1.category }
    }

    // MARK: - Load
    func load(force: Bool = false) async {
        if isLoading { return }
        if !force && !items.isEmpty { return }
        isLoading = true
        defer { isLoading = false }
        do {
            self.items = try await NetworkManager.shared.fetchOwnerMenu(restaurantId: restaurantId)
        } catch {
            present(error)
        }
    }

    func refresh() async {
        await load(force: true)
    }

    // MARK: - Create
    @discardableResult
    func create(payload: OwnerMenuItemPayload) async -> Bool {
        if isSubmitting { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let new = try await NetworkManager.shared.createMenuItem(
                restaurantId: restaurantId,
                payload: payload
            )
            items.append(new)
            return true
        } catch {
            present(error)
            return false
        }
    }

    // MARK: - Update
    @discardableResult
    func update(itemId: Int, payload: OwnerMenuItemPayload) async -> Bool {
        if isSubmitting { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            let updated = try await NetworkManager.shared.updateMenuItem(
                itemId: itemId,
                payload: payload
            )
            if let idx = items.firstIndex(where: { $0.itemId == itemId }) {
                items[idx] = updated
            }
            return true
        } catch {
            present(error)
            return false
        }
    }

    // MARK: - Delete
    @discardableResult
    func delete(itemId: Int) async -> Bool {
        if isSubmitting { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await NetworkManager.shared.deleteMenuItem(itemId: itemId)
            items.removeAll { $0.itemId == itemId }
            return true
        } catch {
            present(error)
            return false
        }
    }

    // MARK: - Helpers
    private func present(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.showError = true
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
