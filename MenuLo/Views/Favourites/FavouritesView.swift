//
//  FavouritesView.swift
//  MenuLo
//
//  MenuLo/Views/Favourites/FavouritesView.swift
//
//  Kullanıcının kalp ikonuyla beğendiği restoranlar ve menü ürünleri.
//  "Low to High" vb. filtrelerle sıralanabilir.
//

import SwiftUI

// MARK: - Mock Models
fileprivate struct FavouriteRestaurant: Identifiable {
    let id = UUID()
    let name: String
    let cuisine: String
    let rating: Double
    let priceRange: String
    let distance: String
    let emoji: String
    let tags: [String]
}

fileprivate struct FavouriteItem: Identifiable {
    let id = UUID()
    let name: String
    let restaurantName: String
    let price: Double
    let emoji: String
    let isGreenMenu: Bool
}

// MARK: - View
struct FavouritesView: View {

    @State private var selectedSegment = 0  // 0 = Restaurants, 1 = Items
    @State private var sortOption = "Rating"
    let sortOptions = ["Rating", "Low to High", "High to Low", "Distance", "A–Z"]

    fileprivate let mockRestaurants: [FavouriteRestaurant] = [
        FavouriteRestaurant(name: "Lezzet Durağı",    cuisine: "Pizza & Burger",   rating: 4.8, priceRange: "₺₺",  distance: "0.8 km", emoji: "🍕", tags: ["Pet Friendly", "Open Now"]),
        FavouriteRestaurant(name: "Deniz Lokantası",  cuisine: "Seafood",           rating: 4.6, priceRange: "₺₺₺", distance: "1.2 km", emoji: "🦐", tags: ["Halal", "Open Now"]),
        FavouriteRestaurant(name: "Green Bowl",        cuisine: "Vegan & Salads",   rating: 4.5, priceRange: "₺",   distance: "0.4 km", emoji: "🥗", tags: ["Vegan", "Gluten Free"]),
        FavouriteRestaurant(name: "Ramen House",       cuisine: "Japanese",          rating: 4.7, priceRange: "₺₺",  distance: "2.1 km", emoji: "🍜", tags: ["Vegetarian Options"]),
        FavouriteRestaurant(name: "Burger Bros",       cuisine: "American",          rating: 4.3, priceRange: "₺",   distance: "0.6 km", emoji: "🍔", tags: ["Open Now", "Pet Friendly"]),
    ]

    fileprivate let mockItems: [FavouriteItem] = [
        FavouriteItem(name: "Margherita Pizza",  restaurantName: "Lezzet Durağı",   price: 149, emoji: "🍕",  isGreenMenu: false),
        FavouriteItem(name: "Acıbadem Kurabiye", restaurantName: "Pastane 1888",    price: 45,  emoji: "🍪",  isGreenMenu: false),
        FavouriteItem(name: "Akşam Özel Tavuk", restaurantName: "Lezzet Durağı",   price: 89,  emoji: "🍗",  isGreenMenu: true),
        FavouriteItem(name: "Tuna Avokado Bowl", restaurantName: "Green Bowl",       price: 119, emoji: "🥑",  isGreenMenu: false),
        FavouriteItem(name: "Wagyu Burger",      restaurantName: "Burger Bros",      price: 199, emoji: "🍔",  isGreenMenu: false),
        FavouriteItem(name: "Matcha Latte",      restaurantName: "Ramen House",      price: 55,  emoji: "🍵",  isGreenMenu: true),
    ]

    fileprivate var sortedRestaurants: [FavouriteRestaurant] {
        switch sortOption {
        case "Low to High": return mockRestaurants.sorted { Double($0.priceRange.count) < Double($1.priceRange.count) }
        case "High to Low": return mockRestaurants.sorted { Double($0.priceRange.count) > Double($1.priceRange.count) }
        case "Rating":      return mockRestaurants.sorted { $0.rating > $1.rating }
        case "Distance":    return mockRestaurants.sorted { $0.distance < $1.distance }
        case "A–Z":         return mockRestaurants.sorted { $0.name < $1.name }
        default:            return mockRestaurants
        }
    }

    fileprivate var sortedItems: [FavouriteItem] {
        switch sortOption {
        case "Low to High":  return mockItems.sorted { $0.price < $1.price }
        case "High to Low":  return mockItems.sorted { $0.price > $1.price }
        case "A–Z":          return mockItems.sorted { $0.name < $1.name }
        default:             return mockItems
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: - Segmented Control
                Picker("Tür", selection: $selectedSegment) {
                    Text("Restoranlar (\(mockRestaurants.count))").tag(0)
                    Text("Ürünler (\(mockItems.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.vertical, MenuLoTheme.Spacing.sm)

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
                                        RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.pill)
                                            .strokeBorder(
                                                sortOption == opt ? Color.clear : MenuLoTheme.Colors.divider,
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.vertical, MenuLoTheme.Spacing.xs)
                }

                Divider()

                // MARK: - Liste
                if selectedSegment == 0 {
                    ScrollView {
                        LazyVStack(spacing: MenuLoTheme.Spacing.md) {
                            ForEach(sortedRestaurants) { restaurant in
                                FavouriteRestaurantCard(restaurant: restaurant)
                            }
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.vertical, MenuLoTheme.Spacing.md)
                    }
                    .transition(.opacity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: MenuLoTheme.Spacing.sm) {
                            ForEach(sortedItems) { item in
                                FavouriteItemRow(item: item)
                            }
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.vertical, MenuLoTheme.Spacing.md)
                    }
                    .transition(.opacity)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Favourites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Favorileri düzenle
                    } label: {
                        Text("Düzenle")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                    }
                }
            }
        }
    }
}

// MARK: - Restoran Kartı
private struct FavouriteRestaurantCard: View {
    let restaurant: FavouriteRestaurant
    @State private var isLiked = true

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {

            // Emoji Avatar
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .fill(MenuLoTheme.Colors.primary.opacity(0.1))
                    .frame(width: 70, height: 70)
                Text(restaurant.emoji)
                    .font(.system(size: 36))
            }

            // İçerik
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(MenuLoTheme.Fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                Text(restaurant.cuisine)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                HStack(spacing: 8) {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", restaurant.rating))
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    }

                    Text("·")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)

                    Text(restaurant.priceRange)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)

                    Text("·")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)

                    HStack(spacing: 2) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                        Text(restaurant.distance)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }

                // Etiketler
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

            // Kalp İkonu
            Button {
                withAnimation(.spring(response: 0.3)) { isLiked.toggle() }
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .foregroundColor(isLiked ? .red : MenuLoTheme.Colors.textSecondary)
                    .font(.title3)
                    .scaleEffect(isLiked ? 1.1 : 1.0)
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Ürün Satırı
private struct FavouriteItemRow: View {
    let item: FavouriteItem
    @State private var isLiked = true

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium)
                    .fill(item.isGreenMenu
                          ? MenuLoTheme.Colors.success.opacity(0.12)
                          : MenuLoTheme.Colors.primary.opacity(0.1))
                    .frame(width: 52, height: 52)
                Text(item.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(item.name)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    if item.isGreenMenu {
                        Image(systemName: "leaf.fill")
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.success)
                    }
                }
                Text(item.restaurantName)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("₺\(Int(item.price))")
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(MenuLoTheme.Colors.primary)

                Button {
                    withAnimation(.spring(response: 0.3)) { isLiked.toggle() }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : MenuLoTheme.Colors.textSecondary)
                        .scaleEffect(isLiked ? 1.1 : 1.0)
                }
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    FavouritesView()
}
