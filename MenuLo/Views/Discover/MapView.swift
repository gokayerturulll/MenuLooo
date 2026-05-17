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
            FilterSheetView(filter: viewModel.filter) { applied in
                Task { await viewModel.applyFilter(applied) }
            }
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

// MARK: - Restaurant Half Sheet (Glassmorphism)
private struct RestaurantHalfSheetView: View {
    let restaurant: Restaurant
    let onMenuTap: () -> Void

    var body: some View {
        VStack(spacing: 14) {

            // Header — emoji avatar + ad + meta
            HStack(spacing: 14) {
                Text(restaurant.emoji)
                    .font(.system(size: 36))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(MenuLoTheme.Colors.primary.opacity(0.18))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(MenuLoTheme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 5) {
                    Text(restaurant.businessName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        }

                        Text("·")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)

                        Text(restaurant.cuisine)
                            .font(.system(size: 13))
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Action — Menüyü Gör (kompakt + gradient)
            Button(action: onMenuTap) {
                HStack(spacing: 8) {
                    Text("Menüyü Gör")
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    LinearGradient(
                        colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview
#Preview {
    MapView()
        .environmentObject(DiscoverViewModel())
}
