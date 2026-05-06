//
//  FavouritesView.swift
//  MenuLo
//
//  Kullanıcının kalp ikonuyla beğendiği restoranlar.
//

import SwiftUI

struct FavouritesView: View {

    @EnvironmentObject var favouritesManager: FavouritesManager
    @StateObject private var viewModel = DiscoverViewModel()
    
    @State private var sortOption = "Rating"
    let sortOptions = ["Rating", "Mesafe", "A–Z"]

    fileprivate var sortedRestaurants: [Restaurant] {
        let favs = viewModel.restaurants.filter { favouritesManager.favoriteRestaurantIDs.contains($0.id) }
        switch sortOption {
        case "Rating":      return favs.sorted { $0.rating > $1.rating }
        case "Mesafe":      return favs.sorted { $0.distance < $1.distance }
        case "A–Z":         return favs.sorted { $0.name < $1.name }
        default:            return favs
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                if sortedRestaurants.isEmpty {
                    // MARK: - Empty State
                    Spacer()
                    VStack(spacing: MenuLoTheme.Spacing.lg) {
                        ZStack {
                            Circle()
                                .fill(MenuLoTheme.Colors.primary.opacity(0.1))
                                .frame(width: 120, height: 120)
                            Image(systemName: "heart.slash")
                                .font(.system(size: 50))
                                .foregroundColor(MenuLoTheme.Colors.primary)
                        }
                        
                        Text("Henüz Favori Mekan Yok")
                            .font(MenuLoTheme.Fonts.title)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        
                        Text("Keşfet ekranından beğendiğin restoranları kalp ikonuna dokunarak buraya ekleyebilirsin.")
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MenuLoTheme.Spacing.xl)
                    }
                    Spacer()
                } else {
                    // MARK: - Üst İstatistik Banner
                    HStack(spacing: 0) {
                        FavStatItem(value: "\(favouritesManager.favoriteRestaurantIDs.count)", label: "Restoran", icon: "building.2.fill", color: MenuLoTheme.Colors.primary)
                    }
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .background(MenuLoTheme.Colors.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

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
                        .padding(.vertical, MenuLoTheme.Spacing.sm)
                    }

                    Divider()

                    // MARK: - Liste
                    ScrollView {
                        LazyVStack(spacing: MenuLoTheme.Spacing.md) {
                            ForEach(sortedRestaurants) { r in
                                FavRestaurantCard(restaurant: r)
                            }
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.vertical, MenuLoTheme.Spacing.md)
                        .padding(.bottom, 90)
                    }
                    .background(MenuLoTheme.Colors.backgroundLight)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Favorilerim")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await viewModel.fetchNearbyRestaurants() }
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
    let restaurant: Restaurant
    @EnvironmentObject var favouritesManager: FavouritesManager

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {

            // Emoji + Gradient Avatar
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .fill(
                        LinearGradient(
                            colors: placeholderColors,
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
                withAnimation(.spring(response: 0.3)) { 
                    favouritesManager.toggleFavorite(restaurantID: restaurant.id) 
                }
            } label: {
                Image(systemName: favouritesManager.isFavorite(restaurantID: restaurant.id) ? "heart.fill" : "heart")
                    .foregroundColor(favouritesManager.isFavorite(restaurantID: restaurant.id) ? .red : MenuLoTheme.Colors.textSecondary)
                    .font(.title3)
                    .scaleEffect(favouritesManager.isFavorite(restaurantID: restaurant.id) ? 1.15 : 1.0)
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }

    private var placeholderColors: [Color] {
        let palettes: [[Color]] = [
            [Color(hex: "#FF6B6B"), Color(hex: "#FFA63B")],
            [Color(hex: "#6C5CE7"), Color(hex: "#A29BFE")],
            [Color(hex: "#00B894"), Color(hex: "#55EFC4")],
            [Color(hex: "#0984E3"), Color(hex: "#74B9FF")],
            [Color(hex: "#E17055"), Color(hex: "#FAB1A0")],
            [Color(hex: "#FDCB6E"), Color(hex: "#E0752A")]
        ]
        let idx = abs(restaurant.name.hashValue) % palettes.count
        return palettes[idx]
    }
}

// MARK: - Preview
#Preview {
    FavouritesView()
        .environmentObject(FavouritesManager())
}
