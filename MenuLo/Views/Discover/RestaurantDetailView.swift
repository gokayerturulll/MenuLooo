import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @State private var menuData: MenuData? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.lg) {

                // MARK: - Header Section
                VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.xs) {
                    HStack {
                        Text(restaurant.emoji)
                            .font(.system(size: 48))
                            .padding(MenuLoTheme.Spacing.sm)
                            .background(MenuLoTheme.Colors.primary.opacity(0.1))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(restaurant.businessName)
                                .font(MenuLoTheme.Fonts.title)
                                .foregroundColor(.primary)

                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .font(.caption)
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                Text(restaurant.address ?? "Adres bilgisi yok")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        DetailBadge(iconName: "fork.knife", text: restaurant.cuisine)
                        DetailBadge(iconName: "star.fill", text: String(format: "%.1f", restaurant.rating), iconColor: .yellow)
                    }
                    .padding(.horizontal)
                }
                .padding(.top, MenuLoTheme.Spacing.md)

                Divider()
                    .padding(.horizontal)

                // MARK: - Menu Content
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Menü yükleniyor...")
                            .progressViewStyle(CircularProgressViewStyle(tint: MenuLoTheme.Colors.primary))
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else if let error = errorMessage {
                    VStack(spacing: MenuLoTheme.Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(.primary)

                        Button("Tekrar Dene") {
                            Task {
                                await loadMenu()
                            }
                        }
                        .font(MenuLoTheme.Fonts.button)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                } else if let categories = menuData?.categories, !categories.isEmpty {
                    ForEach(categories) { category in
                        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
                            Text(category.categoryName)
                                .font(MenuLoTheme.Fonts.subtitle)
                                .foregroundColor(.primary)
                                .padding(.horizontal)

                            ForEach(category.items) { item in
                                MenuDetailItemRow(item: item)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, MenuLoTheme.Spacing.md)
                    }
                } else {
                    VStack {
                        Image(systemName: "menucard")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Bu restorana ait menü bulunmuyor.")
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding()
                }
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle(restaurant.businessName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadMenu()
        }
    }

    private func loadMenu() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await NetworkManager.shared.fetchRestaurantMenu(restaurantId: restaurant.id)
            self.menuData = data
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Subviews

private struct DetailBadge: View {
    let iconName: String
    let text: String
    var iconColor: Color = MenuLoTheme.Colors.primary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.footnote)
                .foregroundColor(iconColor)
            Text(text)
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.small))
    }
}

private struct MenuDetailItemRow: View {
    let item: MenuDetailItem
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(MenuLoTheme.Fonts.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text(item.formattedPrice)
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .padding(.top, 2)
            }
            Spacer()

            // Eğer resim url varsa, ekleyebiliriz
            if let imgUrl = item.imageUrl, let url = URL(string: imgUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
        .shadow(color: Color.primary.opacity(0.05), radius: 5, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2), value: isPressed)
    }
}
