//
//  MenuManagerView.swift
//  MenuLo
//
//  MenuLo/Views/Business/MenuManagerView.swift
//
//  İşletme sahiplerinin menü ürünlerini yönettiği (ekleme/düzenleme) ekran.
//  "Yeşil Menü" ürünü eklerken özel input alanları ve expiry timer sunulur.
//

import SwiftUI

// MARK: - Mock Menu Item
fileprivate struct MockMenuItem: Identifiable {
    let id = UUID()
    var name: String
    var category: String
    var price: Double
    var isGreenMenu: Bool
    var isAvailable: Bool
    var emoji: String
}

// MARK: - MenuManagerView
struct MenuManagerView: View {

    @State fileprivate var menuItems: [MockMenuItem] = [
        MockMenuItem(name: "Margherita Pizza",    category: "Pizza",       price: 149, isGreenMenu: false, isAvailable: true,  emoji: "🍕"),
        MockMenuItem(name: "Klasik Burger",        category: "Burger",      price: 129, isGreenMenu: false, isAvailable: true,  emoji: "🍔"),
        MockMenuItem(name: "Sezar Salata",         category: "Salata",      price: 89,  isGreenMenu: false, isAvailable: true,  emoji: "🥗"),
        MockMenuItem(name: "Günün Çorbası",        category: "Çorba",       price: 45,  isGreenMenu: false, isAvailable: false, emoji: "🍲"),
        MockMenuItem(name: "Kırmızı Kadife Kek",  category: "Tatlı",       price: 69,  isGreenMenu: false, isAvailable: true,  emoji: "🍰"),
        MockMenuItem(name: "Akşam Özel Tavuk",    category: "Ana Yemek",   price: 159, isGreenMenu: true,  isAvailable: true,  emoji: "🍗"),
    ]

    @State private var showAddSheet    = false
    @State private var selectedCategory = "Tümü"

    let categories = ["Tümü", "Pizza", "Burger", "Salata", "Çorba", "Ana Yemek", "Tatlı", "İçecek"]

    fileprivate var filteredItems: [MockMenuItem] {
        selectedCategory == "Tümü"
            ? menuItems
            : menuItems.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: - Kategori Filtresi
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        ForEach(categories, id: \.self) { cat in
                            CategoryChip(
                                label: cat,
                                isSelected: selectedCategory == cat
                            ) {
                                withAnimation { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .padding(.vertical, MenuLoTheme.Spacing.sm)
                }
                .background(MenuLoTheme.Colors.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

                // MARK: - Menü Listesi
                if filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: MenuLoTheme.Spacing.md) {
                        Text("🍽️").font(.system(size: 56))
                        Text("Bu kategoride ürün yok")
                            .font(MenuLoTheme.Fonts.subtitle)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            MenuItemRow(item: item)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { indexSet in
                            menuItems.remove(atOffsets: indexSet)
                        }
                    }
                    .listStyle(.plain)
                    .background(MenuLoTheme.Colors.backgroundLight)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Menu Manager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddMenuItemSheet { newItem in
                    menuItems.append(newItem)
                }
            }
        }
    }
}

// MARK: - Menü Ürün Satırı
private struct MenuItemRow: View {
    let item: MockMenuItem

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            // Emoji Avatar
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium)
                    .fill(item.isGreenMenu
                          ? MenuLoTheme.Colors.success.opacity(0.12)
                          : MenuLoTheme.Colors.primary.opacity(0.1))
                    .frame(width: 56, height: 56)
                Text(item.emoji)
                    .font(.system(size: 28))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    if item.isGreenMenu {
                        Label("Green Menu", systemImage: "leaf.fill")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MenuLoTheme.Colors.success.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(item.category)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                Text("₺\(Int(item.price))")
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(MenuLoTheme.Colors.primary)
            }

            Spacer()

            VStack(spacing: 4) {
                Circle()
                    .fill(item.isAvailable ? MenuLoTheme.Colors.success : MenuLoTheme.Colors.error)
                    .frame(width: 10, height: 10)
                Text(item.isAvailable ? "Aktif" : "Pasif")
                    .font(.caption2)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Ürün Ekleme Sheet
struct AddMenuItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    fileprivate let onAdd: (MockMenuItem) -> Void

    @State private var name        = ""
    @State private var category    = "Pizza"
    @State private var price       = ""
    @State private var isGreenMenu = false

    // Yeşil Menü Özel Alanları
    @State private var greenQuantity    = ""
    @State private var greenDescription = ""
    @State private var expiryHour: Double = 2.0   // saat cinsinden

    let categories = ["Pizza", "Burger", "Salata", "Çorba", "Ana Yemek", "Tatlı", "İçecek"]
    let categoryEmojis: [String: String] = [
        "Pizza": "🍕", "Burger": "🍔", "Salata": "🥗",
        "Çorba": "🍲", "Ana Yemek": "🍗", "Tatlı": "🍰", "İçecek": "🥤"
    ]

    var isFormValid: Bool { !name.isEmpty && !price.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // --- Temel Bilgiler ---
                    FormSection(title: "Ürün Bilgileri") {
                        CustomTextField(placeholder: "Ürün Adı", iconName: "tag.fill", text: $name)
                        CustomTextField(placeholder: "Fiyat (₺)", iconName: "turkishlirasign.circle.fill", text: $price)
                            .keyboardType(.decimalPad)

                        // Kategori Picker
                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                .frame(width: 24)
                            Picker("Kategori", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(MenuLoTheme.Colors.primary)
                            Spacer()
                        }
                        .padding()
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    // --- Yeşil Menü Toggle ---
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
                        Toggle(isOn: $isGreenMenu.animation()) {
                            HStack(spacing: MenuLoTheme.Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(MenuLoTheme.Colors.success.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "leaf.fill")
                                        .foregroundColor(MenuLoTheme.Colors.success)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yeşil Menü Ürünü")
                                        .font(MenuLoTheme.Fonts.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                    Text("Gıda israfını önlemek için indirimli fiyatla sun")
                                        .font(.caption)
                                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                }
                            }
                        }
                        .tint(MenuLoTheme.Colors.success)
                        .padding(MenuLoTheme.Spacing.md)
                        .background(isGreenMenu
                                    ? MenuLoTheme.Colors.success.opacity(0.08)
                                    : MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                .strokeBorder(
                                    isGreenMenu ? MenuLoTheme.Colors.success.opacity(0.4) : Color.clear,
                                    lineWidth: 1.5
                                )
                        )

                        // --- Yeşil Menü Özel Alanları ---
                        if isGreenMenu {
                            VStack(spacing: MenuLoTheme.Spacing.md) {
                                CustomTextField(
                                    placeholder: "Miktar (örn: 5 porsiyon)",
                                    iconName: "number.circle.fill",
                                    text: $greenQuantity
                                )
                                .keyboardType(.numberPad)

                                // Açıklama
                                HStack(alignment: .top, spacing: MenuLoTheme.Spacing.sm) {
                                    Image(systemName: "text.alignleft")
                                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                        .frame(width: 24)
                                        .padding(.top, 2)

                                    TextField("Kısa açıklama (örn: %30 indirimli akşam özel)", text: $greenDescription, axis: .vertical)
                                        .font(MenuLoTheme.Fonts.body)
                                        .lineLimit(3)
                                }
                                .padding()
                                .background(MenuLoTheme.Colors.cardBackground)
                                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                                // Bitiş Süresi Slider
                                VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
                                    HStack {
                                        Image(systemName: "timer.circle.fill")
                                            .foregroundColor(MenuLoTheme.Colors.warning)
                                        Text("Bitiş Süresi (Expiry Timer)")
                                            .font(MenuLoTheme.Fonts.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                        Spacer()
                                        Text(expiryLabel)
                                            .font(MenuLoTheme.Fonts.button)
                                            .foregroundColor(MenuLoTheme.Colors.warning)
                                    }

                                    Slider(value: $expiryHour, in: 0.5...12, step: 0.5)
                                        .tint(MenuLoTheme.Colors.warning)

                                    Label("Süre dolduğunda ürün otomatik olarak listeden kaldırılır.",
                                          systemImage: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                }
                                .padding(MenuLoTheme.Spacing.md)
                                .background(MenuLoTheme.Colors.warning.opacity(0.08))
                                .cornerRadius(MenuLoTheme.CornerRadius.large)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                        .strokeBorder(MenuLoTheme.Colors.warning.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // Kaydet Butonu
                    PrimaryButton(title: "Ürünü Kaydet") {
                        let newItem = MockMenuItem(
                            name: name,
                            category: category,
                            price: Double(price) ?? 0,
                            isGreenMenu: isGreenMenu,
                            isAvailable: true,
                            emoji: categoryEmojis[category] ?? "🍽️"
                        )
                        onAdd(newItem)
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Yeni Ürün Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }

    private var expiryLabel: String {
        expiryHour < 1
            ? "\(Int(expiryHour * 60)) dk"
            : expiryHour == 1 ? "1 saat" : "\(String(format: "%.1g", expiryHour)) saat"
    }
}

// MARK: - Form Section
private struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            Text(title)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: MenuLoTheme.Spacing.md) {
                content
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Category Chip
private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textSecondary)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
                .background(isSelected ? MenuLoTheme.Colors.primary : Color.clear)
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
        }
    }
}

// MARK: - Preview
#Preview {
    MenuManagerView()
}
