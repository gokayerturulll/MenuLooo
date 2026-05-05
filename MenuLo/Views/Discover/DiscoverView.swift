//
//  DiscoverView.swift
//  MenuLo
//
//  Keşfet ekranı — Arama çubuğu + Kategori chips + Zengin restoran kartları.
//

import SwiftUI

// MARK: - Mock Restoran Modeli
fileprivate struct MockRestaurant: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let rating: Double
    let reviewCount: Int
    let distance: String
    let priceRange: String
    let tags: [String]
    let emoji: String
    let isOpen: Bool
    let deliveryTime: String
}



// MARK: - DiscoverView
struct DiscoverView: View {

    @State private var searchText       = ""
    @State private var selectedCategory = "Tümü"
    @State private var showFilterSheet  = false
    @State private var viewMode: ViewMode = .list   // list / map

    enum ViewMode { case list, map }

    let categories = ["Tümü", "🍕 Pizza", "🍔 Burger", "🥗 Vegan", "🍣 Sushi", "🍰 Tatlı", "🍜 Ramen", "🦐 Deniz Ürünleri", "☕️ Kahve"]

    fileprivate let restaurants: [MockRestaurant] = [
        MockRestaurant(name: "Gusto Pizzeria",      cuisine: "İtalyan",    rating: 4.8, reviewCount: 312, distance: "0.4 km", priceRange: "₺₺",  tags: ["Pizza", "Vegan Option"],      emoji: "🍕", isOpen: true,  deliveryTime: "20–30 dk"),
        MockRestaurant(name: "Kadıköy Burger House",cuisine: "Amerikan",   rating: 4.7, reviewCount: 198, distance: "0.7 km", priceRange: "₺",    tags: ["Burger", "Pet Friendly"],     emoji: "🍔", isOpen: true,  deliveryTime: "15–25 dk"),
        MockRestaurant(name: "Green Bowl",          cuisine: "Vegan",      rating: 4.6, reviewCount: 241, distance: "0.9 km", priceRange: "₺₺",  tags: ["Vegan", "Gluten Free"],       emoji: "🥗", isOpen: true,  deliveryTime: "25–35 dk"),
        MockRestaurant(name: "Ramen House Tokyo",   cuisine: "Japon",      rating: 4.5, reviewCount: 175, distance: "1.1 km", priceRange: "₺₺",  tags: ["Ramen", "Sushi"],             emoji: "🍜", isOpen: false, deliveryTime: "30–40 dk"),
        MockRestaurant(name: "Pastane 1888",        cuisine: "Pastane",    rating: 4.9, reviewCount: 523, distance: "0.3 km", priceRange: "₺",    tags: ["Tatlı", "Kahve"],             emoji: "🍰", isOpen: true,  deliveryTime: "10–15 dk"),
        MockRestaurant(name: "Deniz Lokantası",     cuisine: "Türk/Deniz", rating: 4.6, reviewCount: 289, distance: "1.5 km", priceRange: "₺₺₺", tags: ["Seafood", "Halal"],           emoji: "🦐", isOpen: true,  deliveryTime: "35–50 dk"),
        MockRestaurant(name: "Sushi Boshi",         cuisine: "Japon",      rating: 4.4, reviewCount: 132, distance: "2.0 km", priceRange: "₺₺₺", tags: ["Sushi", "Vegetarian Option"], emoji: "🍣", isOpen: true,  deliveryTime: "40–50 dk"),
        MockRestaurant(name: "Kahve Durağı",        cuisine: "Kafe",       rating: 4.7, reviewCount: 410, distance: "0.2 km", priceRange: "₺",    tags: ["Kahve", "Tatlı"],             emoji: "☕️", isOpen: true,  deliveryTime: "5–10 dk"),
    ]

    fileprivate var filteredRestaurants: [MockRestaurant] {
        let catFiltered: [MockRestaurant]
        if selectedCategory == "Tümü" {
            catFiltered = restaurants
        } else {
            let cleanCat = selectedCategory.components(separatedBy: " ").dropFirst().joined(separator: " ")
            catFiltered = restaurants.filter { $0.tags.contains(where: { $0.contains(cleanCat) }) || $0.cuisine.contains(cleanCat) }
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
                                    Text("\(restaurants.count) mekan bulundu")
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
                                RestaurantCard(restaurant: restaurant)
                                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                            }
                        }
                    }
                    .padding(.top, MenuLoTheme.Spacing.sm)
                    .padding(.bottom, 90) // FAB için boşluk
                }
                .background(MenuLoTheme.Colors.backgroundLight)
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
    let restaurant: MockRestaurant
    @State private var isFav = false

    var body: some View {
        VStack(spacing: 0) {

            // Kapak Fotoğrafı (placeholder)
            ZStack(alignment: .topTrailing) {
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

                // Durum Rozeti
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
                .padding(10)

                // Kalp İkonu
                Button {
                    withAnimation(.spring(response: 0.3)) { isFav.toggle() }
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundColor(isFav ? .red : .white)
                        .font(.system(size: 18, weight: .semibold))
                        .shadow(color: .black.opacity(0.3), radius: 4)
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
struct FilterSheetView: View {
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
}

