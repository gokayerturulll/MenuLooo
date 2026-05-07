//
//  RestaurantDetailView.swift
//  MenuLo
//
//  Restoran detayı + menüsü. Yapışkan kategori barı (Getir/Yemeksepeti tarzı)
//  ve kategoriye anchor'lı scroll davranışı içerir.
//

import SwiftUI

struct RestaurantDetailView: View {
    let restaurant: Restaurant

    @State private var menuData: MenuData? = nil
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedCategory: String? = nil
    @State private var showMenuBot: Bool = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: - Header (normal akış — scroll'la beraber yukarı kayar)
                    headerSection
                        .padding(.bottom, MenuLoTheme.Spacing.md)

                    // MARK: - Menü içeriği
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if let categories = menuData?.categories, !categories.isEmpty {
                        // Yapışkan başlık + scroll anchor
                        LazyVStack(
                            alignment: .leading,
                            spacing: MenuLoTheme.Spacing.md,
                            pinnedViews: [.sectionHeaders]
                        ) {
                            Section {
                                ForEach(categories) { category in
                                    categorySection(category)
                                        .id(category.categoryName)
                                }
                            } header: {
                                StickyCategoryBar(
                                    categories: categories.map(\.categoryName),
                                    selected: selectedCategory,
                                    onTap: { name in
                                        scrollTo(name, with: proxy)
                                    }
                                )
                            }
                        }
                        .padding(.bottom, MenuLoTheme.Spacing.xxl)
                    } else {
                        emptyView
                    }
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle(restaurant.businessName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showMenuBot = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 6, x: 0, y: 2)
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accessibilityLabel("Yapay Zekaya Sor")
                }
            }
            .fullScreenCover(isPresented: $showMenuBot) {
                // Spesifik restoran context'i — MenuBot sadece bu restoranın menüsünde arar
                MenuBotView(restaurantId: restaurant.id)
            }
            .task { await loadMenu() }
        }
    }

    // MARK: - Subsections

    private var headerSection: some View {
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
                DetailBadge(iconName: "star.fill",
                            text: String(format: "%.1f", restaurant.rating),
                            iconColor: .yellow)
            }
            .padding(.horizontal)
        }
        .padding(.top, MenuLoTheme.Spacing.md)
    }

    private func categorySection(_ category: MenuCategory) -> some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            Text(category.categoryName)
                .font(MenuLoTheme.Fonts.subtitle)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top, MenuLoTheme.Spacing.sm)

            ForEach(category.items) { item in
                MenuDetailItemRow(item: item)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, MenuLoTheme.Spacing.md)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Menü yükleniyor...")
                .progressViewStyle(CircularProgressViewStyle(tint: MenuLoTheme.Colors.primary))
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: MenuLoTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(error)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Button("Tekrar Dene") {
                Task { await loadMenu() }
            }
            .font(MenuLoTheme.Fonts.button)
            .foregroundColor(MenuLoTheme.Colors.primary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }

    private var emptyView: some View {
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

    // MARK: - Actions

    private func scrollTo(_ name: String, with proxy: ScrollViewProxy) {
        // Önce seçili state'i güncelle (UI feedback anında),
        // sonra animasyonlu scroll. anchor: .top sticky bar'ın hemen altına yapıştırır.
        selectedCategory = name
        withAnimation(.easeInOut(duration: 0.4)) {
            proxy.scrollTo(name, anchor: .top)
        }
    }

    private func loadMenu() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await NetworkManager.shared.fetchRestaurantMenu(restaurantId: restaurant.id)
            self.menuData = data
            // İlk kategori otomatik seçili gelsin (sticky bar'da vurgu için)
            if selectedCategory == nil, let first = data.categories.first?.categoryName {
                self.selectedCategory = first
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Sticky Category Bar
private struct StickyCategoryBar: View {
    let categories: [String]
    let selected: String?
    let onTap: (String) -> Void

    var body: some View {
        ScrollViewReader { hProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MenuLoTheme.Spacing.sm) {
                    ForEach(categories, id: \.self) { cat in
                        CategoryPill(label: cat, isSelected: selected == cat) {
                            onTap(cat)
                        }
                        .id(cat) // yatay scroll için inner anchor
                    }
                }
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
            }
            .background(.regularMaterial) // sticky bar arka planı (blur)
            .overlay(alignment: .bottom) {
                Divider().opacity(0.4)
            }
            .onChange(of: selected) { newValue in
                // Seçili kategori değiştiğinde yatay barda da görünür hale gelsin
                guard let v = newValue else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    hProxy.scrollTo(v, anchor: .center)
                }
            }
        }
    }
}

private struct CategoryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
                .background(
                    isSelected
                        ? AnyView(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                                startPoint: .leading, endPoint: .trailing
                            )
                          )
                        : AnyView(Color(.tertiarySystemFill))
                )
                .clipShape(Capsule())
                .shadow(
                    color: isSelected ? MenuLoTheme.Colors.primary.opacity(0.3) : .clear,
                    radius: 5
                )
        }
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
