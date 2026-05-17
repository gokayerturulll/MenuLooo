//
//  FilterSheetView.swift
//  MenuLo
//
//  Discover ve Map ekranlarının ortak filtre çekmecesi.
//  Backend'in beklediği `RestaurantFilter` üzerinde lokal bir taslak (`draft`)
//  ile çalışır; kullanıcı "Uygula" basana kadar parent state değişmez.
//

import SwiftUI

struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: RestaurantFilter
    private let onApply: (RestaurantFilter) -> Void

    init(filter: RestaurantFilter, onApply: @escaping (RestaurantFilter) -> Void) {
        self._draft = State(initialValue: filter)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.lg) {

                    // Diyet Tercihleri
                    FilterSection(title: "Diyet Tercihleri", icon: "leaf.fill") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: MenuLoTheme.Spacing.sm) {
                            ForEach(DietaryTag.allCases) { tag in
                                DietTagButton(
                                    label: tag.displayLabel,
                                    isOn: Binding(
                                        get: { draft.dietaryTags.contains(tag) },
                                        set: { isOn in
                                            if isOn { draft.dietaryTags.insert(tag) }
                                            else    { draft.dietaryTags.remove(tag) }
                                        }
                                    )
                                )
                            }
                        }
                    }

                    Divider().padding(.horizontal)

                    // İşletme Özellikleri
                    FilterSection(title: "İşletme Özellikleri", icon: "building.2.fill") {
                        FilterToggleRow(
                            label: "Şu An Açık",
                            icon: "clock.badge.checkmark.fill",
                            iconColor: MenuLoTheme.Colors.success,
                            isOn: $draft.openNow
                        )
                    }

                    Divider().padding(.horizontal)

                    // Maksimum Mesafe (konum yoksa pasif)
                    FilterSection(title: "Maksimum Mesafe", icon: "location.circle.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            HStack {
                                Text("0.5 km")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                Spacer()
                                Text(draft.radiusKm.map { String(format: "%.1f km", $0) } ?? "Sınırsız")
                                    .font(MenuLoTheme.Fonts.button)
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                Spacer()
                                Text("20 km")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            }
                            Slider(
                                value: Binding(
                                    get: { draft.radiusKm ?? 0 },
                                    set: { newValue in
                                        draft.radiusKm = newValue < 0.5 ? nil : newValue
                                    }
                                ),
                                in: 0...20, step: 0.5
                            )
                            .tint(MenuLoTheme.Colors.primary)
                            Text("0.5 km altında değer sınırsız anlamına gelir.")
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, 4)
                    }

                    Divider().padding(.horizontal)

                    // Sıralama
                    FilterSection(title: "Sıralama", icon: "arrow.up.arrow.down") {
                        VStack(spacing: MenuLoTheme.Spacing.xs) {
                            ForEach(RestaurantSortOption.allCases) { option in
                                Button {
                                    withAnimation { draft.sort = option }
                                } label: {
                                    HStack {
                                        Text(option.displayLabel)
                                            .font(MenuLoTheme.Fonts.body)
                                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                        Spacer()
                                        if draft.sort == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(MenuLoTheme.Colors.primary)
                                        } else {
                                            Circle()
                                                .strokeBorder(MenuLoTheme.Colors.divider, lineWidth: 1.5)
                                                .frame(width: 22, height: 22)
                                        }
                                    }
                                    .padding(MenuLoTheme.Spacing.md)
                                    .background(
                                        draft.sort == option
                                            ? MenuLoTheme.Colors.primary.opacity(0.08)
                                            : MenuLoTheme.Colors.cardBackground
                                    )
                                    .cornerRadius(MenuLoTheme.CornerRadius.medium)
                                }
                            }
                        }
                    }

                    PrimaryButton(title: "Filtreleri Uygula") {
                        onApply(draft)
                        dismiss()
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Filtrele & Sırala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Temizle") {
                        draft = RestaurantFilter()
                    }
                    .foregroundColor(MenuLoTheme.Colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Helpers

private struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                Text(title)
                    .font(MenuLoTheme.Fonts.subtitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            content
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

private struct DietTagButton: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button { withAnimation { isOn.toggle() } } label: {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(isOn ? .semibold : .regular)
                .foregroundColor(isOn ? .white : MenuLoTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
                .background(isOn ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.cardBackground)
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.pill)
                        .strokeBorder(
                            isOn ? Color.clear : MenuLoTheme.Colors.divider,
                            lineWidth: 1.5
                        )
                )
                .shadow(color: isOn ? MenuLoTheme.Colors.primary.opacity(0.3) : .clear, radius: 6)
        }
    }
}

private struct FilterToggleRow: View {
    let label: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 28)
            Text(label)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(MenuLoTheme.Colors.primary)
                .labelsHidden()
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.medium)
    }
}
