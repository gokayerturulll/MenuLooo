//
//  FavouritesView.swift
//  MenuLo
//
//  Kullanıcının kalp ikonuyla beğendiği restoranlar ve menü ürünleri.
//  DiscoverView mock restoran verisinden 3 tanesi seçildi.
//

import SwiftUI

// MARK: - Mock Models (fileprivate — aynı dosya scope'u)
fileprivate struct FavouriteRestaurant: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let rating: Double
    let reviewCount: Int
    let priceRange: String
    let distance: String
    let emoji: String
    let tags: [String]
    let gradientColors: [Color]
}

fileprivate struct FavouriteItem: Identifiable {
    let id = UUID()
    let name: String
    let restaurantName: String
    let price: Double
    let emoji: String
    let isGreenMenu: Bool
}

// MARK: - FavouritesView
struct FavouritesView: View {

    @State private var selectedSegment = 0
    @State private var sortOption = "Rating"
    let sortOptions = ["Rating", "Low to High", "High to Low", "Distance", "A–Z"]

    fileprivate let mockRestaurants: [FavouriteRestaurant] = [
        FavouriteRestaurant(
            name: "Gusto Pizzeria", cuisine: "İtalyan", rating: 4.8, reviewCount: 312,
            priceRange: "₺₺", distance: "0.4 km", emoji: "🍕",
            tags: ["Pizza", "Vegan Option"],
            gradientColors: [Color(hex: "#FF6B6B"), Color(hex: "#FFA63B")]
        ),
        FavouriteRestaurant(
            name: "Kadıköy Burger House", cuisine: "Amerikan", rating: 4.7, reviewCount: 198,
            priceRange: "₺", distance: "0.7 km", emoji: "🍔",
            tags: ["Burger", "Pet Friendly"],
            gradientColors: [Color(hex: "#E17055"), Color(hex: "#FAB1A0")]
        ),
        FavouriteRestaurant(
            name: "Green Bowl", cuisine: "Vegan", rating: 4.6, reviewCount: 241,
            priceRange: "₺₺", distance: "0.9 km", emoji: "🥗",
            tags: ["Vegan", "Gluten Free"],
            gradientColors: [Color(hex: "#00B894"), Color(hex: "#55EFC4")]
        ),
        FavouriteRestaurant(
            name: "Pastane 1888", cuisine: "Pastane", rating: 4.9, reviewCount: 523,
            priceRange: "₺", distance: "0.3 km", emoji: "🍰",
            tags: ["Tatlı", "Kahve"],
            gradientColors: [Color(hex: "#FDCB6E"), Color(hex: "#E0752A")]
        ),
    ]

    fileprivate let mockItems: [FavouriteItem] = [
        FavouriteItem(name: "Margherita Pizza",   restaurantName: "Gusto Pizzeria",        price: 149, emoji: "🍕", isGreenMenu: false),
        FavouriteItem(name: "Wagyu Burger",        restaurantName: "Kadıköy Burger House",  price: 199, emoji: "🍔", isGreenMenu: false),
        FavouriteItem(name: "Akşam Özel Tavuk",   restaurantName: "Green Bowl",            price: 89,  emoji: "🍗", isGreenMenu: true),
        FavouriteItem(name: "Kırmızı Kadife Kek", restaurantName: "Pastane 1888",          price: 65,  emoji: "🍰", isGreenMenu: false),
        FavouriteItem(name: "Matcha Latte",        restaurantName: "Kahve Durağı",          price: 55,  emoji: "🍵", isGreenMenu: true),
    ]

    fileprivate var sortedRestaurants: [FavouriteRestaurant] {
        switch sortOption {
        case "Low to High": return mockRestaurants.sorted { $0.priceRange.count < $1.priceRange.count }
        case "High to Low": return mockRestaurants.sorted { $0.priceRange.count > $1.priceRange.count }
        case "Rating":      return mockRestaurants.sorted { $0.rating > $1.rating }
        case "Distance":    return mockRestaurants.sorted { $0.distance < $1.distance }
        case "A–Z":         return mockRestaurants.sorted { $0.name < $1.name }
        default:            return mockRestaurants
        }
    }

    fileprivate var sortedItems: [FavouriteItem] {
        switch sortOption {
        case "Low to High": return mockItems.sorted { $0.price < $1.price }
        case "High to Low": return mockItems.sorted { $0.price > $1.price }
        case "A–Z":         return mockItems.sorted { $0.name < $1.name }
        default:            return mockItems
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: - Üst İstatistik Banner
                HStack(spacing: 0) {
                    FavStatItem(value: "\(mockRestaurants.count)", label: "Restoran", icon: "building.2.fill", color: MenuLoTheme.Colors.primary)
                    Divider().frame(height: 36)
                    FavStatItem(value: "\(mockItems.count)", label: "Ürün", icon: "fork.knife", color: MenuLoTheme.Colors.success)
                    Divider().frame(height: 36)
                    FavStatItem(value: "4.7", label: "Ort. Puan", icon: "star.fill", color: .yellow)
                }
                .padding(.vertical, MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

                // MARK: - Segmented Control
                Picker("Tür", selection: $selectedSegment) {
                    Text("Restoranlar (\(mockRestaurants.count))").tag(0)
                    Text("Ürünler (\(mockItems.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.vertical, MenuLoTheme.Spacing.md)

                // MARK: - Sort Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)

                        ForEach(sortOptions, id: \.self) { opt in
                            Button {
                                withAnimation { sortOption = opt }
                            } label: {
                                Text(opt)
                                    .font(MenuLoTheme.Fonts.caption)
                                    .fontWeight(sortOption == opt ? .semibold : .regular)
                                    .foregroundColor(sortOption == opt ? .white : MenuLoTheme.Colors.textSecondary)
                                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                                    .padding(.vertical, 6)
                                    .background(sortOption == opt ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.cardBackground)
                                    .cornerRadius(MenuLoTheme.CornerRadius.pill)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                sortOption == opt ? Color.clear : MenuLoTheme.Colors.divider,
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.sm)
                }

                Divider()

                // MARK: - Liste
                ScrollView {
                    LazyVStack(spacing: MenuLoTheme.Spacing.md) {
                        if selectedSegment == 0 {
                            ForEach(sortedRestaurants) { r in
                                FavRestaurantCard(restaurant: r)
                            }
                        } else {
                            ForEach(sortedItems) { item in
                                FavItemRow(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .padding(.bottom, 90)
                    .animation(.spring(response: 0.35), value: selectedSegment)
                }
                .background(MenuLoTheme.Colors.backgroundLight)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {  } label: {
                        Text("Düzenle")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Stat Item
private struct FavStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Restoran Kartı
private struct FavRestaurantCard: View {
    let restaurant: FavouriteRestaurant
    @State private var isLiked = true

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {

            // Emoji + Gradient Avatar
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: restaurant.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Text(restaurant.emoji)
                    .font(.system(size: 36))
            }

            // Bilgiler
            VStack(alignment: .leading, spacing: 5) {
                Text(restaurant.name)
                    .font(MenuLoTheme.Fonts.body)
                    .fontWeight(.bold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text(restaurant.cuisine)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        Text("(\(restaurant.reviewCount))")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                    Text("·")
                        .foregroundColor(MenuLoTheme.Colors.divider)
                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                        Text(restaurant.distance)
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                    Text("·")
                        .foregroundColor(MenuLoTheme.Colors.divider)
                    Text(restaurant.priceRange)
                        .font(.caption2)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }

                // Tags
                HStack(spacing: 4) {
                    ForEach(restaurant.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MenuLoTheme.Colors.primary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3)) { isLiked.toggle() }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : MenuLoTheme.Colors.textSecondary)
                    .font(.title3)
                    .scaleEffect(isLiked ? 1.15 : 1.0)
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Ürün Satırı
private struct FavItemRow: View {
    let item: FavouriteItem
    @State private var isLiked = true

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium)
                    .fill(item.isGreenMenu
                        ? MenuLoTheme.Colors.success.opacity(0.15)
                        : MenuLoTheme.Colors.primary.opacity(0.1))
                    .frame(width: 56, height: 56)
                Text(item.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        .lineLimit(1)
                    if item.isGreenMenu {
                        Label("Yeşil", systemImage: "leaf.fill")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.success)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(MenuLoTheme.Colors.success.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(item.restaurantName)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("₺\(Int(item.price))")
                    .font(MenuLoTheme.Fonts.button)
                    .fontWeight(.bold)
                    .foregroundColor(MenuLoTheme.Colors.primary)

                Button {
                    withAnimation(.spring(response: 0.3)) { isLiked.toggle() }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : MenuLoTheme.Colors.textSecondary)
                        .scaleEffect(isLiked ? 1.15 : 1.0)
                }
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    FavouritesView()
}
