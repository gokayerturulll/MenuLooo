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

struct MapView: View {
    @EnvironmentObject var viewModel: DiscoverViewModel
    @State private var searchText     = ""
    @State private var showFilterSheet = false

    // Harita — Kadıköy merkez
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.990, longitude: 29.025),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedRestaurant: Restaurant? = nil
    @State private var path = NavigationPath()
    @FocusState private var isSearchFocused: Bool

    private var searchResults: [Restaurant] {
        viewModel.searchResults(for: searchText)
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Discover")
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Restaurant.self) { restaurant in
                    RestaurantDetailView(restaurant: restaurant)
                }
        }
    }

    private var content: some View {
        ZStack(alignment: .top) {

            // MARK: - Tam Ekran Harita
            Map(
                coordinateRegion: $mapRegion,
                showsUserLocation: true,
                annotationItems: viewModel.restaurants
            ) { restaurant in
                MapAnnotation(coordinate: restaurant.coordinate) {
                    RestaurantMapPin(restaurant: restaurant) {
                        selectedRestaurant = restaurant
                    }
                }
            }
            .ignoresSafeArea(edges: .top)

            // MARK: - Üstte Yüzen Arama + Filtre + Sonuç Listesi
            VStack(spacing: MenuLoTheme.Spacing.sm) {
                HStack(spacing: MenuLoTheme.Spacing.sm) {
                    // Arama Çubuğu
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)

                        TextField("Mekan veya lezzet ara...", text: $searchText)
                            .font(MenuLoTheme.Fonts.body)
                            .focused($isSearchFocused)
                            .submitLabel(.search)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                isSearchFocused = false
                            } label: {
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

                // MARK: - Arama Sonuçları (Autocomplete)
                if !searchText.isEmpty {
                    SearchResultsOverlay(
                        results: searchResults,
                        onSelect: { focusOnRestaurant($0) }
                    )
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Spacer()

                // Konumuma Git Butonu
                HStack {
                    Spacer()
                    Button {
                        if let userLoc = viewModel.userLocation {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                mapRegion = MKCoordinateRegion(
                                    center: userLoc,
                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                )
                            }
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
            .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheetView()
        }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantHalfSheetView(restaurant: restaurant) {
                let target = restaurant
                selectedRestaurant = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    path.append(target)
                }
            }
            .presentationDetents([.fraction(0.32)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Camera Fly-to + Auto Sheet
    private func focusOnRestaurant(_ restaurant: Restaurant) {
        searchText = ""
        isSearchFocused = false

        withAnimation(.easeInOut(duration: 0.6)) {
            mapRegion = MKCoordinateRegion(
                center: restaurant.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
        }

        // Kamera kayması bittikten sonra yarım sheet otomatik açılsın
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            selectedRestaurant = restaurant
        }
    }
}

// MARK: - Search Results Overlay
private struct SearchResultsOverlay: View {
    let results: [Restaurant]
    let onSelect: (Restaurant) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if results.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    Text("Eşleşen restoran bulunamadı")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    Spacer()
                }
                .padding(MenuLoTheme.Spacing.md)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { index, r in
                            Button {
                                onSelect(r)
                            } label: {
                                SearchResultRow(restaurant: r)
                            }
                            .buttonStyle(.plain)

                            if index < results.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .background(.regularMaterial)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

private struct SearchResultRow: View {
    let restaurant: Restaurant

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            Text(restaurant.emoji)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(MenuLoTheme.Colors.primary.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(restaurant.businessName)
                    .font(MenuLoTheme.Fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption2)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    Text(restaurant.address ?? restaurant.cuisine)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "arrow.up.left")
                .font(.footnote)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
        .padding(.horizontal, MenuLoTheme.Spacing.md)
        .padding(.vertical, MenuLoTheme.Spacing.sm)
        .contentShape(Rectangle())
    }
}

// MARK: - Harita Pini
private struct RestaurantMapPin: View {
    let restaurant: Restaurant
    @State private var isExpanded = false
    let onTap: () -> Void

    var body: some View {
        Button {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
            onTap()
        } label: {
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

// MARK: - Restaurant Half Sheet
private struct RestaurantHalfSheetView: View {
    let restaurant: Restaurant
    let onMenuTap: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: MenuLoTheme.Spacing.md) {
                Text(restaurant.emoji)
                    .font(.system(size: 44))
                    .padding(8)
                    .background(MenuLoTheme.Colors.primary.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.businessName)
                        .font(MenuLoTheme.Fonts.title)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(MenuLoTheme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        Text("•")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        Text(restaurant.cuisine)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal)
            
            Button {
                onMenuTap()
            } label: {
                Text("Menüyü Gör")
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MenuLoTheme.Colors.primary)
                    .cornerRadius(MenuLoTheme.CornerRadius.medium)
                    .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding(.top)
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
    }
}

// MARK: - Filtre Sheet
private struct FilterSheetView: View {
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
    MapView()
        .environmentObject(DiscoverViewModel())
}
