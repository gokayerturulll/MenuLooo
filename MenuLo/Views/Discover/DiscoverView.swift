//
//  DiscoverView.swift
//  MenuLo
//
//  Keşfet ekranı — Arama çubuğu + Kategori chips + Zengin restoran kartları.
//

import SwiftUI

// MARK: - DiscoverView
struct DiscoverView: View {

    @State private var searchText       = ""
    @State private var selectedCategory = "Tümü"
    @State private var showFilterSheet  = false
    @State private var viewMode: ViewMode = .list   // list / map

    enum ViewMode { case list, map }

    let categories = ["Tümü", "🍕 Pizza", "🍔 Burger", "🥗 Vegan", "🍣 Sushi", "🍰 Tatlı", "🍜 Ramen", "🦐 Deniz Ürünleri", "☕️ Kahve"]

    @EnvironmentObject var viewModel: DiscoverViewModel

    fileprivate var filteredRestaurants: [Restaurant] {
        let sourceList = Array(viewModel.restaurants.prefix(10))
        let catFiltered: [Restaurant]
        if selectedCategory == "Tümü" {
            catFiltered = sourceList
        } else {
            let cleanCat = selectedCategory.components(separatedBy: " ").dropFirst().joined(separator: " ")
            catFiltered = sourceList.filter { $0.tags.contains(where: { $0.contains(cleanCat) }) || $0.cuisine.contains(cleanCat) }
        }
        guard !searchText.isEmpty else { return catFiltered }
        return catFiltered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.cuisine.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: - Search Bar
                HStack(spacing: MenuLoTheme.Spacing.sm) {
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .font(.system(size: 16, weight: .medium))

                        TextField("Mekan veya lezzet ara...", text: $searchText)
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                            .autocorrectionDisabled()

                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .padding(.vertical, 11)
                    .background(MenuLoTheme.Colors.cardBackground)
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)

                    // Filtre Butonu
                    Button { showFilterSheet = true } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                .fill(MenuLoTheme.Colors.primary)
                                .frame(width: 44, height: 44)
                                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 8, x: 0, y: 3)
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.sm)
                .padding(.bottom, MenuLoTheme.Spacing.sm)

                // MARK: - Kategori Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        ForEach(categories, id: \.self) { cat in
                            DiscoverCategoryChip(label: cat, isSelected: selectedCategory == cat) {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.vertical, MenuLoTheme.Spacing.xs)
                }

                Divider()

                // MARK: - Restoran Listesi
                ScrollView {
                    LazyVStack(spacing: MenuLoTheme.Spacing.md) {

                        // "Popüler" Header
                        if searchText.isEmpty && selectedCategory == "Tümü" {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yakınındaki Lezzetler")
                                        .font(MenuLoTheme.Fonts.title)
                                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                    Text("\(viewModel.restaurants.count) mekan bulundu")
                                        .font(MenuLoTheme.Fonts.caption)
                                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "location.fill")
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                    .font(.body)
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                            .padding(.top, MenuLoTheme.Spacing.sm)
                        }

                        if filteredRestaurants.isEmpty {
                            VStack(spacing: MenuLoTheme.Spacing.md) {
                                Text("🔍").font(.system(size: 52))
                                Text("Sonuç bulunamadı")
                                    .font(MenuLoTheme.Fonts.subtitle)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                Text("Farklı bir arama veya kategori dene")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else {
                            ForEach(filteredRestaurants) { restaurant in
                                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                    RestaurantCard(restaurant: restaurant)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                            }
                        }
                    }
                    .padding(.top, MenuLoTheme.Spacing.sm)
                    .padding(.bottom, 90) // FAB için boşluk
                }
                .background(MenuLoTheme.Colors.backgroundLight)
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView()
            }
        }
    }
}

// MARK: - Restoran Kartı
private struct RestaurantCard: View {
    let restaurant: Restaurant
    @EnvironmentObject var favouritesManager: FavouritesManager

    var body: some View {
        VStack(spacing: 0) {

            // Kapak Fotoğrafı (placeholder)
            ZStack {
                // Gradient Placeholder
                LinearGradient(
                    colors: placeholderColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 160)
                .overlay(
                    VStack {
                        Text(restaurant.emoji)
                            .font(.system(size: 52))
                        Text(restaurant.cuisine)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.25))
                            .cornerRadius(8)
                    }
                )

                // Üst Bar (Durum Rozeti & Kalp İkonu)
                HStack(alignment: .top) {
                    // Durum Rozeti (Sol Üst)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(restaurant.isOpen ? MenuLoTheme.Colors.success : MenuLoTheme.Colors.error)
                            .frame(width: 7, height: 7)
                        Text(restaurant.isOpen ? "Açık" : "Kapalı")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.45))
                    .cornerRadius(MenuLoTheme.CornerRadius.pill)

                    Spacer()

                    // Kalp İkonu (Sağ Üst)
                    Button {
                        withAnimation(.spring(response: 0.3)) { 
                            favouritesManager.toggleFavorite(restaurantID: restaurant.id)
                        }
                    } label: {
                        Image(systemName: favouritesManager.isFavorite(restaurantID: restaurant.id) ? "heart.fill" : "heart")
                            .foregroundColor(favouritesManager.isFavorite(restaurantID: restaurant.id) ? .red : .white)
                            .font(.system(size: 18, weight: .semibold))
                            .shadow(color: .black.opacity(0.3), radius: 4)
                    }
                }
                .padding(12)
                .frame(maxHeight: .infinity, alignment: .top)
            }

            // MARK: - Bilgi Kısmı
            VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {

                // Ad + Rating
                HStack(alignment: .top) {
                    Text(restaurant.name)
                        .font(MenuLoTheme.Fonts.subtitle)
                        .fontWeight(.bold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(MenuLoTheme.Fonts.caption)
                            .fontWeight(.bold)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        Text("(\(restaurant.reviewCount))")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }

                // Etiketler
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(restaurant.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.primary)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(MenuLoTheme.Colors.primary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Meta bilgiler
                HStack(spacing: 12) {
                    Label(restaurant.distance, systemImage: "location.fill")
                    Label(restaurant.deliveryTime, systemImage: "clock")
                    Label(restaurant.priceRange, systemImage: "turkishlirasign.circle")
                }
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .padding(MenuLoTheme.Spacing.md)
        }
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.09), radius: 14, x: 0, y: 5)
        .clipped()
    }

    private var placeholderColors: [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "#FF6B6B"), Color(hex: "#FFA63B")],
            [Color(hex: "#6C5CE7"), Color(hex: "#A29BFE")],
            [Color(hex: "#00B894"), Color(hex: "#55EFC4")],
            [Color(hex: "#0984E3"), Color(hex: "#74B9FF")],
            [Color(hex: "#E17055"), Color(hex: "#FAB1A0")],
            [Color(hex: "#FDCB6E"), Color(hex: "#E0752A")],
            [Color(hex: "#2D3436"), Color(hex: "#636E72")],
            [Color(hex: "#6C5CE7"), Color(hex: "#FFA63B")],
        ]
        let idx = abs(restaurant.name.hashValue) % palettes.count
        return palettes[idx]
    }
}

// MARK: - Kategori Chip
private struct DiscoverCategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textPrimary)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
                .background(
                    isSelected
                        ? AnyView(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                          )
                        : AnyView(MenuLoTheme.Colors.cardBackground)
                )
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                .shadow(
                    color: isSelected ? MenuLoTheme.Colors.primary.opacity(0.35) : .black.opacity(0.05),
                    radius: 5
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : MenuLoTheme.Colors.divider,
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Filter Sheet
private struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var dietTags: [String: Bool] = [
        "🌱 Vegan": false, "🌾 Gluten Free": false,
        "🥦 Vegetarian": false, "☪️ Helal": false
    ]
    @State private var isOpenNow    = false
    @State private var isPetFriendly = false
    @State private var distance: Double = 5
    @State private var sortOption   = "En İyi Eşleşme"

    let sortOptions = ["En İyi Eşleşme", "En Yüksek Puan", "En Düşük Fiyat", "En Yüksek Fiyat", "En Yakın"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // Diyet Etiketleri
                    FilterSection(title: "Diyet Tercihleri", icon: "leaf.fill") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(Array(dietTags.keys.sorted()), id: \.self) { tag in
                                Toggle(isOn: Binding(
                                    get: { dietTags[tag] ?? false },
                                    set: { dietTags[tag] = $0 }
                                )) {
                                    Text(tag)
                                        .font(MenuLoTheme.Fonts.caption)
                                }
                                .toggleStyle(.button)
                                .tint(MenuLoTheme.Colors.success)
                            }
                        }
                    }

                    // İşletme Özellikleri
                    FilterSection(title: "İşletme Özellikleri", icon: "building.2.fill") {
                        VStack(spacing: 10) {
                            Toggle("Şu An Açık", isOn: $isOpenNow)
                                .tint(MenuLoTheme.Colors.primary)
                            Divider()
                            Toggle("Evcil Hayvan Dostu 🐾", isOn: $isPetFriendly)
                                .tint(MenuLoTheme.Colors.primary)
                        }
                    }

                    // Mesafe
                    FilterSection(title: "Maksimum Mesafe", icon: "location.circle.fill") {
                        VStack(spacing: 8) {
                            HStack {
                                Text("\(String(format: "%.0f", distance)) km")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                Spacer()
                            }
                            Slider(value: $distance, in: 0.5...20, step: 0.5)
                                .tint(MenuLoTheme.Colors.primary)
                            HStack { Text("0.5 km"); Spacer(); Text("20 km") }
                                .font(.caption)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                    }

                    // Sıralama
                    FilterSection(title: "Sırala", icon: "arrow.up.arrow.down") {
                        ForEach(sortOptions, id: \.self) { opt in
                            Button {
                                withAnimation { sortOption = opt }
                            } label: {
                                HStack {
                                    Text(opt)
                                        .font(MenuLoTheme.Fonts.body)
                                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                    Spacer()
                                    if sortOption == opt {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(MenuLoTheme.Colors.primary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }

                    PrimaryButton(title: "Filtreleri Uygula") { dismiss() }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sıfırla") {
                        dietTags.keys.forEach { dietTags[$0] = false }
                        isOpenNow = false; isPetFriendly = false
                        distance = 5; sortOption = "En İyi Eşleşme"
                    }.foregroundColor(MenuLoTheme.Colors.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Filter Section Container
private struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .font(.footnote)
                Text(title)
                    .font(MenuLoTheme.Fonts.subtitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            content
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 6)
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
    }
}


// MARK: - Preview
#Preview {
    DiscoverView()
        .environmentObject(DiscoverViewModel())
        .environmentObject(FavouritesManager())
}

