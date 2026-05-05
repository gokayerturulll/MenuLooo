//
//  DiscoverView.swift
//  MenuLo
//
//  MenuLo/Views/Discover/DiscoverView.swift
//
//  Tam ekran harita + arama çubuğu + gelişmiş filtre drawer.
//

import SwiftUI
import MapKit

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchText     = ""
    @State private var showFilterSheet = false

    // Harita — Kadıköy merkez
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.990, longitude: 29.025),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack(alignment: .top) {

            // MARK: - Tam Ekran Harita
            Map(
                coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: viewModel.restaurants
            ) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    RestaurantMapPin(restaurant: restaurant)
                }
            }
            .ignoresSafeArea(edges: .top)

            // MARK: - Üstte Yüzen Arama + Filtre
            VStack(spacing: 0) {
                HStack(spacing: MenuLoTheme.Spacing.sm) {
                    // Arama Çubuğu
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)

                        TextField("Mekan veya lezzet ara...", text: $searchText)
                            .font(MenuLoTheme.Fonts.body)

                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(MenuLoTheme.Spacing.md)
                    .background(.regularMaterial)
                    .cornerRadius(MenuLoTheme.CornerRadius.pill)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Filtre Butonu
                    Button {
                        showFilterSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(MenuLoTheme.Colors.primary)
                                .frame(width: 48, height: 48)
                                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 8)
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.top, MenuLoTheme.Spacing.sm)

                Spacer()

                // Konumuma Git Butonu
                HStack {
                    Spacer()
                    Button {
                        if let userLoc = viewModel.userLocation {
                            withAnimation { mapRegion.center = userLoc }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(MenuLoTheme.Colors.primary)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, MenuLoTheme.Spacing.md)
                    .padding(.bottom, MenuLoTheme.Spacing.lg)
                }
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView()
        }
        .onAppear {
            Task { await viewModel.fetchNearbyRestaurants() }
        }
    }
}

// MARK: - Harita Pini
private struct RestaurantMapPin: View {
    let restaurant: Restaurant
    @State private var isExpanded = false

    var body: some View {
        Button { withAnimation(.spring()) { isExpanded.toggle() } } label: {
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "fork.knife")
                        .font(.caption2)
                    if isExpanded {
                        Text(restaurant.name)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(MenuLoTheme.Colors.primary)
                .clipShape(Capsule())
                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 4)

                Image(systemName: "triangle.fill")
                    .font(.system(size: 6))
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .rotationEffect(.degrees(180))
            }
        }
    }
}

// MARK: - Filtre Sheet
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    // Diyet Etiketleri
    @State private var isVegan        = false
    @State private var isGlutenFree   = false
    @State private var isVegetarian   = false
    @State private var isHalal        = false

    // İşletme Özellikleri
    @State private var openNow        = false
    @State private var petFriendly    = false

    // Mesafe
    @State private var maxDistance: Double = 5.0  // km

    // Sıralama
    @State private var sortOption     = "Best Match"
    let sortOptions = ["Best Match", "Rating", "Price: Low to High", "Price: High to Low"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.lg) {

                    // MARK: - Diyet Etiketleri
                    FilterSection(title: "Diyet Tercihleri", icon: "leaf.fill") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: MenuLoTheme.Spacing.sm) {
                            DietTagButton(label: "🌱 Vegan",       isOn: $isVegan)
                            DietTagButton(label: "🌾 Gluten Free", isOn: $isGlutenFree)
                            DietTagButton(label: "🥦 Vegetarian",  isOn: $isVegetarian)
                            DietTagButton(label: "☪️ Helal",       isOn: $isHalal)
                        }
                    }

                    Divider().padding(.horizontal)

                    // MARK: - İşletme Özellikleri
                    FilterSection(title: "İşletme Özellikleri", icon: "building.2.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            FilterToggleRow(
                                label: "Şu An Açık",
                                icon: "clock.badge.checkmark.fill",
                                iconColor: MenuLoTheme.Colors.success,
                                isOn: $openNow
                            )
                            FilterToggleRow(
                                label: "Evcil Hayvan Dostu",
                                icon: "pawprint.fill",
                                iconColor: Color(hex: "#A29BFE"),
                                isOn: $petFriendly
                            )
                        }
                    }

                    Divider().padding(.horizontal)

                    // MARK: - Mesafe Filtresi
                    FilterSection(title: "Maksimum Mesafe", icon: "location.circle.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            HStack {
                                Text("0 km")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                Spacer()
                                Text("\(Int(maxDistance)) km")
                                    .font(MenuLoTheme.Fonts.button)
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                Spacer()
                                Text("20 km")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            }
                            Slider(value: $maxDistance, in: 0...20, step: 0.5)
                                .tint(MenuLoTheme.Colors.primary)
                        }
                        .padding(.horizontal, 4)
                    }

                    Divider().padding(.horizontal)

                    // MARK: - Sıralama
                    FilterSection(title: "Sıralama", icon: "arrow.up.arrow.down") {
                        VStack(spacing: MenuLoTheme.Spacing.xs) {
                            ForEach(sortOptions, id: \.self) { option in
                                Button {
                                    withAnimation { sortOption = option }
                                } label: {
                                    HStack {
                                        Text(option)
                                            .font(MenuLoTheme.Fonts.body)
                                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                        Spacer()
                                        if sortOption == option {
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
                                        sortOption == option
                                            ? MenuLoTheme.Colors.primary.opacity(0.08)
                                            : MenuLoTheme.Colors.cardBackground
                                    )
                                    .cornerRadius(MenuLoTheme.CornerRadius.medium)
                                }
                            }
                        }
                    }

                    // MARK: - Uygula Butonu
                    PrimaryButton(title: "Filtreleri Uygula") {
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
                        isVegan = false; isGlutenFree = false
                        isVegetarian = false; isHalal = false
                        openNow = false; petFriendly = false
                        maxDistance = 5.0; sortOption = "Best Match"
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

// MARK: - Filtre Yardımcı Bileşenler

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
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        DiscoverView()
    }
}
