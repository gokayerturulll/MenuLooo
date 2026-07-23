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

    /// Chip etiketi → backend `restaurant.categories` değerleri.
    /// `dbValue == nil` → "Tümü" (kategori filtresi uygulanmaz).
    /// Seed dosyasındaki kategori sözlüğüyle birebir hizalı:
    /// Pizza, Hamburger, Salata, Sushi, Steak, Döner, Makarna, Çorba, Tatlı, Deniz Ürünleri, Ramen, Vegan, Kahve.
    static let categoryOptions: [(label: String, dbValue: String?)] = [
        ("Tümü",                nil),
        ("🍕 Pizza",            "Pizza"),
        ("🍔 Burger",           "Hamburger"),
        ("🥗 Vegan",            "Vegan"),
        ("🥬 Salata",           "Salata"),
        ("🍣 Sushi",            "Sushi"),
        ("🥩 Steak",            "Steak"),
        ("🥙 Döner",            "Döner"),
        ("🍝 Makarna",          "Makarna"),
        ("🍲 Çorba",            "Çorba"),
        ("🍰 Tatlı",            "Tatlı"),
        ("🍜 Ramen",            "Ramen"),
        ("🦐 Deniz Ürünleri",  "Deniz Ürünleri"),
        ("☕️ Kahve",            "Kahve"),
    ]

    @EnvironmentObject var viewModel: DiscoverViewModel

    fileprivate var filteredRestaurants: [Restaurant] {
        // Kategori filtresi artık backend tarafında uygulanıyor (viewModel.filter.category).
        // Burada yalnızca yerel arama metni uygulanır.
        let sourceList = viewModel.restaurants
        guard !searchText.isEmpty else { return sourceList }
        return sourceList.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.cuisine.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func dbValue(for label: String) -> String? {
        Self.categoryOptions.first(where: { $0.label == label })?.dbValue
    }

    var body: some View {
        VStack(spacing: 0) {

                // MARK: - Custom Header
                HStack {
                    Text("Keşfet")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.xs)
                .padding(.bottom, MenuLoTheme.Spacing.sm)

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
                        ForEach(Self.categoryOptions, id: \.label) { option in
                            DiscoverCategoryChip(label: option.label, isSelected: selectedCategory == option.label) {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = option.label }
                                Task { await viewModel.applyCategory(option.dbValue) }
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

                        // "Öne Çıkanlar" horizontal scroll — API'den gelen ilk 5 yüksek puanlı restoran
                        if searchText.isEmpty && selectedCategory == "Tümü" {
                            FeaturedRestaurantsSection(restaurants: Array(viewModel.restaurants.prefix(5)))
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
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(filter: viewModel.filter) { applied in
                    Task { await viewModel.applyFilter(applied) }
                }
            }
    }
}

// MARK: - Öne Çıkanlar
private struct FeaturedRestaurantsSection: View {
    let restaurants: [Restaurant]

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            HStack {
                Text("Öne Çıkanlar")
                    .font(MenuLoTheme.Fonts.subtitle)
                    .fontWeight(.bold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            if restaurants.isEmpty {
                Text("Yakında")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        ForEach(restaurants) { restaurant in
                            NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                                FeaturedCard(restaurant: restaurant)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }
            }
        }
        .padding(.bottom, MenuLoTheme.Spacing.sm)
    }
}

private struct FeaturedCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 140, height: 100)
                .cornerRadius(MenuLoTheme.CornerRadius.large)

                Text(restaurant.emoji)
                    .font(.system(size: 36))
            }

            Text(restaurant.name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                .lineLimit(1)
                .frame(width: 140, alignment: .leading)

            if restaurant.rating > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", restaurant.rating))
                        .font(.caption2)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var gradientColors: [Color] {
        restaurantGradient(cuisine: restaurant.cuisineType ?? restaurant.cuisine, seed: restaurant.restaurantId)
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
                            favouritesManager.toggle(restaurant.id)
                        }
                    } label: {
                        Image(systemName: favouritesManager.isFavourite(restaurant.id) ? "heart.fill" : "heart")
                            .foregroundColor(favouritesManager.isFavourite(restaurant.id) ? .red : .white)
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
                        if restaurant.rating > 0 {
                            Text(String(format: "%.1f", restaurant.rating))
                                .font(MenuLoTheme.Fonts.caption)
                                .fontWeight(.bold)
                                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                            Text("(\(restaurant.reviewCountDisplay))")
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        } else {
                            Text("Yeni")
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
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
                    Label(restaurant.isOpen ? "Açık" : "Kapalı",
                          systemImage: restaurant.isOpen ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(restaurant.isOpen ? MenuLoTheme.Colors.success : MenuLoTheme.Colors.error)
                    Label(restaurant.priceRangeDisplay, systemImage: "turkishlirasign.circle")
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
        restaurantGradient(cuisine: restaurant.cuisineType ?? restaurant.cuisine, seed: restaurant.restaurantId)
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
                                colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
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

// MARK: - Cuisine → gradient helper (shared across RestaurantCard + FeaturedCard)
private func restaurantGradient(cuisine: String, seed: Int) -> [Color] {
    let lower = cuisine.lowercased()
    if lower.contains("pizza")  { return [.red.opacity(0.85), .orange] }
    if lower.contains("burger") { return [MenuLoTheme.Colors.error, MenuLoTheme.Colors.warning] }
    if lower.contains("sushi") || lower.contains("japon") { return [MenuLoTheme.Colors.accentBlue, MenuLoTheme.Colors.accentBlueLight] }
    if lower.contains("vegan") || lower.contains("veget") { return [MenuLoTheme.Colors.success, MenuLoTheme.Colors.accentMint] }
    if lower.contains("tatlı") || lower.contains("kafe") || lower.contains("kahve") { return [MenuLoTheme.Colors.warning, MenuLoTheme.Colors.accentDeepOrange] }
    if lower.contains("deniz") || lower.contains("balık") { return [MenuLoTheme.Colors.accentBlue, MenuLoTheme.Colors.success] }
    if lower.contains("ramen") || lower.contains("asya") { return [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight] }
    let defaults: [[Color]] = [
        [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
        [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight],
        [MenuLoTheme.Colors.success, MenuLoTheme.Colors.accentMint],
        [MenuLoTheme.Colors.accentBlue, MenuLoTheme.Colors.accentBlueLight],
    ]
    return defaults[abs(seed) % defaults.count]
}

// MARK: - Preview
#Preview {
    DiscoverView()
        .environmentObject(DiscoverViewModel.preview())
        .environmentObject(FavouritesManager.shared)
}

