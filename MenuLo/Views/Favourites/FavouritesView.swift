//
//  FavouritesView.swift
//  MenuLo
//
//  Kullanıcının kalp ikonuyla beğendiği restoranlar.
//

import SwiftUI

struct FavouritesView: View {

    @EnvironmentObject var favouritesManager: FavouritesManager
    @EnvironmentObject var viewModel: DiscoverViewModel

    @State private var sortOption = "Rating"
    let sortOptions = ["Rating", "Mesafe", "A–Z"]

    fileprivate var sortedRestaurants: [Restaurant] {
        let favs = viewModel.restaurants.filter { favouritesManager.favouriteIds.contains($0.id) }
        switch sortOption {
        case "Rating":      return favs.sorted { $0.rating > $1.rating }
        case "Mesafe":      return favs.sorted { $0.distance < $1.distance }
        case "A–Z":         return favs.sorted { $0.name < $1.name }
        default:            return favs
        }
    }

    var body: some View {
        VStack(spacing: 0) {

                // MARK: - Custom Header
                HStack {
                    Text("Favorilerim")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.xs)
                .padding(.bottom, MenuLoTheme.Spacing.sm)

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
                        FavStatItem(value: "\(favouritesManager.favouriteIds.count)", label: "Restoran", icon: "building.2.fill", color: MenuLoTheme.Colors.primary)
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
                    // List kullanıyoruz çünkü swipeActions sadece List satırlarında
                    // çalışıyor. Sade görünüm için plainListStyle + scrollContentBackground hidden.
                    List {
                        ForEach(sortedRestaurants) { r in
                            FavRestaurantCard(restaurant: r)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6,
                                                          leading: MenuLoTheme.Spacing.lg,
                                                          bottom: 6,
                                                          trailing: MenuLoTheme.Spacing.lg))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.3)) {
                                            favouritesManager.remove(r.id)
                                        }
                                    } label: {
                                        Label("Sil", systemImage: "heart.slash.fill")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(MenuLoTheme.Colors.backgroundLight)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
        .background(MenuLoTheme.Colors.backgroundLight)
        .navigationBarHidden(true)
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
                        Text("(\(restaurant.reviewCountDisplay))")
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
                    Text(restaurant.priceRangeDisplay)
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
                    favouritesManager.toggle(restaurant.id)
                }
            } label: {
                Image(systemName: favouritesManager.isFavourite(restaurant.id) ? "heart.fill" : "heart")
                    .foregroundColor(favouritesManager.isFavourite(restaurant.id) ? .red : MenuLoTheme.Colors.textSecondary)
                    .font(.title3)
                    .scaleEffect(favouritesManager.isFavourite(restaurant.id) ? 1.15 : 1.0)
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
    }

    private var placeholderColors: [Color] {
        let palettes: [[Color]] = [
            [MenuLoTheme.Colors.accentRed, MenuLoTheme.Colors.primary],
            [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight],
            [MenuLoTheme.Colors.success, MenuLoTheme.Colors.accentMint],
            [MenuLoTheme.Colors.accentBlue, MenuLoTheme.Colors.accentBlueLight],
            [MenuLoTheme.Colors.error, MenuLoTheme.Colors.accentPeach],
            [MenuLoTheme.Colors.warning, MenuLoTheme.Colors.accentDeepOrange]
        ]
        let idx = abs(restaurant.name.hashValue) % palettes.count
        return palettes[idx]
    }
}

// MARK: - Preview
#Preview {
    FavouritesView()
        .environmentObject(FavouritesManager.shared)
        .environmentObject(DiscoverViewModel())
}
