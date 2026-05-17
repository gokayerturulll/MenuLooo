//
//  MenuManagerView.swift
//  MenuLo
//
//  MenuLo/Views/Business/MenuManagerView.swift
//
//  İşletme menü yönetimi (CRUD) — backend'e bağlı.
//  - Listeyi `MenuManagerViewModel.load()` çeker.
//  - Ekle/Güncelle/Sil işlemleri NetworkManager üzerinden async çalışır.
//  - UI loading / error / empty state'lerini yansıtır.
//

import SwiftUI
import PhotosUI

// MARK: - MenuManagerView
struct MenuManagerView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel: MenuManagerViewModel

    @State private var editingItem: OwnerMenuItem? = nil
    @State private var showAddSheet = false
    @State private var selectedCategory = "Tümü"

    let categories = ["Tümü", "Pizza", "Burger", "Salata", "Çorba", "Ana Yemek", "Tatlı", "İçecek"]

    init(restaurantId: Int = 1) {
        _viewModel = StateObject(wrappedValue: MenuManagerViewModel(restaurantId: restaurantId))
    }

    /// Ekranda gösterilecek kategori grupları (sıralı, boşları atlamış).
    private var visibleGroups: [(category: String, items: [OwnerMenuItem])] {
        if selectedCategory == "Tümü" {
            return viewModel.groupedByCategory
        }
        let filtered = viewModel.items.filter { $0.category == selectedCategory }
        return filtered.isEmpty ? [] : [(selectedCategory, filtered)]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: MenuLoTheme.Spacing.lg) {

                StatsBanner(
                    total: viewModel.totalCount,
                    active: viewModel.activeCount,
                    green: viewModel.greenCount
                )
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.md)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        ForEach(categories, id: \.self) { cat in
                            CategoryChip(
                                label: cat,
                                isSelected: selectedCategory == cat
                            ) {
                                withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
                            }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }

                // İçerik state'lerine göre
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingState()
                        .padding(.top, MenuLoTheme.Spacing.xl)
                } else if visibleGroups.isEmpty {
                    EmptyMenuState { showAddSheet = true }
                        .padding(.top, MenuLoTheme.Spacing.xl)
                } else {
                    VStack(spacing: MenuLoTheme.Spacing.lg) {
                        ForEach(visibleGroups, id: \.category) { group in
                            MenuCategoryGroup(
                                title: group.category,
                                icon: iconForCategory(group.category),
                                count: group.items.count
                            ) {
                                VStack(spacing: 0) {
                                    ForEach(Array(group.items.enumerated()), id: \.element.itemId) { idx, item in
                                        ManagerItemRow(
                                            item: item,
                                            onEdit: { editingItem = item },
                                            onDelete: {
                                                Task { await viewModel.delete(itemId: item.itemId) }
                                            },
                                            onPhotoData: { data in
                                                Task { await viewModel.uploadPhoto(itemId: item.itemId, imageData: data) }
                                            }
                                        )
                                        if idx < group.items.count - 1 {
                                            Divider().padding(.leading, 88)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: MenuLoTheme.Spacing.xxl)
            }
        }
        .refreshable { await viewModel.refresh() }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Menu Manager")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .tint(MenuLoTheme.Colors.primary)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .font(.title2)
                    }
                }
                .disabled(viewModel.isSubmitting)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddMenuItemSheet { payload in
                Task { await viewModel.create(payload: payload) }
            }
        }
        .sheet(item: $editingItem) { item in
            EditMenuItemSheet(
                item: item,
                onUpdate: { payload in
                    Task { await viewModel.update(itemId: item.itemId, payload: payload) }
                },
                onDelete: {
                    Task { await viewModel.delete(itemId: item.itemId) }
                }
            )
        }
        .alert("Bir sorun oluştu", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) { viewModel.clearError() }
            Button("Tekrar Dene") {
                viewModel.clearError()
                Task { await viewModel.refresh() }
            }
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
        .task {
            // Cache guard'ı load()'da var; çoklu mount'larda spam'lemez.
            await viewModel.load()
        }
    }

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Pizza":     return "circle.grid.2x2.fill"
        case "Burger":    return "circle.hexagongrid.fill"
        case "Salata":    return "leaf.fill"
        case "Çorba":     return "cup.and.saucer.fill"
        case "Ana Yemek": return "fork.knife"
        case "Tatlı":     return "birthday.cake.fill"
        case "İçecek":    return "wineglass.fill"
        default:          return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Loading
private struct LoadingState: View {
    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MenuLoTheme.Colors.primary))
                .scaleEffect(1.4)
            Text("Menü yükleniyor…")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Stats Banner
private struct StatsBanner: View {
    let total: Int
    let active: Int
    let green: Int

    var body: some View {
        HStack(spacing: 0) {
            StatCell(value: "\(total)",  label: "Toplam Ürün",  icon: "tray.full.fill", color: MenuLoTheme.Colors.primary)
            Divider().frame(height: 36)
            StatCell(value: "\(active)", label: "Aktif",        icon: "checkmark.circle.fill", color: MenuLoTheme.Colors.success)
            Divider().frame(height: 36)
            StatCell(value: "\(green)",  label: "Yeşil Menü",   icon: "leaf.fill", color: MenuLoTheme.Colors.success)
        }
        .padding(.vertical, MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                .strokeBorder(MenuLoTheme.Colors.divider, lineWidth: 1)
        )
        .shadow(color: .primary.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

private struct StatCell: View {
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
                    .foregroundColor(.primary)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Kategori Grup
private struct MenuCategoryGroup<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .font(.footnote)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Text("\(count) ürün")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemFill))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: 0) { content }
                .background(MenuLoTheme.Colors.cardBackground)
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .shadow(color: .primary.opacity(0.05), radius: 6)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Manager Item Row
private struct ManagerItemRow: View {
    let item: OwnerMenuItem
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onPhotoData: (Data) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var photoError: String?

    /// Backend image_url'i "/uploads/menu/abc.jpg" formatında dönüyor;
    /// apiBaseURL'in /api kısmını çıkarıp host root'una ekleyerek tam URL kur.
    private func absoluteImageURL(from path: String) -> URL? {
        if let u = URL(string: path), u.scheme != nil { return u }     // zaten tam URL
        let host = AppConstants.apiBaseURL.replacingOccurrences(of: "/api", with: "")
        let prefix = path.hasPrefix("/") ? "" : "/"
        return URL(string: "\(host)\(prefix)\(path)")
    }

    var body: some View {
        Button(action: onEdit) { rowContent }
            .buttonStyle(.plain)
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $photoItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: photoItem) { newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        // 5 MB hard limit — backend de aynı sınırı dayatıyor
                        if data.count > 5 * 1024 * 1024 {
                            photoError = "Fotoğraf 5 MB sınırını aşıyor."
                        } else {
                            onPhotoData(data)
                        }
                    }
                    // Tekrar seçim için reset
                    photoItem = nil
                }
            }
            .alert("Fotoğraf hatası", isPresented: .constant(photoError != nil)) {
                Button("Tamam") { photoError = nil }
            } message: {
                Text(photoError ?? "")
            }
    }

    private var emoji: String {
        switch item.category {
        case "Pizza":     return "🍕"
        case "Burger":    return "🍔"
        case "Salata":    return "🥗"
        case "Çorba":     return "🍲"
        case "Ana Yemek": return "🍗"
        case "Tatlı":     return "🍰"
        case "İçecek":    return "🥤"
        default:          return "🍽️"
        }
    }

    private var rowContent: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium)
                    .fill(item.isGreenMenu
                          ? MenuLoTheme.Colors.success.opacity(0.15)
                          : MenuLoTheme.Colors.primary.opacity(0.12))
                    .frame(width: 56, height: 56)

                // imageUrl varsa fotoğrafı göster (backend /uploads/menu/...);
                // yoksa kategoriye göre emoji placeholder
                if let urlString = item.imageUrl,
                   let url = absoluteImageURL(from: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
                        default:
                            Text(emoji).font(.system(size: 28))
                        }
                    }
                } else {
                    Text(emoji).font(.system(size: 28))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if item.isGreenMenu {
                        Label("Yeşil", systemImage: "leaf.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(MenuLoTheme.Colors.success)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(MenuLoTheme.Colors.success.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                if let desc = item.description, !desc.isEmpty {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    Text(String(format: "₺%.0f", item.price))
                        .font(MenuLoTheme.Fonts.button)
                        .foregroundColor(MenuLoTheme.Colors.primary)

                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.isAvailable ? MenuLoTheme.Colors.success : MenuLoTheme.Colors.error)
                            .frame(width: 6, height: 6)
                        Text(item.isAvailable ? "Aktif" : "Pasif")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Menu {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label(item.imageUrl == nil ? "Fotoğraf Ekle" : "Fotoğrafı Değiştir",
                          systemImage: "photo.fill")
                }
                Button(action: onEdit) {
                    Label("Düzenle", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, MenuLoTheme.Spacing.md)
        .padding(.vertical, MenuLoTheme.Spacing.md)
        .contentShape(Rectangle())
    }
}

// MARK: - Boş Durum
private struct EmptyMenuState: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(MenuLoTheme.Colors.primary.opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: "tray.full")
                    .font(.system(size: 44))
                    .foregroundColor(MenuLoTheme.Colors.primary)
            }

            VStack(spacing: 6) {
                Text("Henüz ürün yok")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(.primary)
                Text("İlk menü öğeni ekleyerek başla — saniyeler içinde hazır.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MenuLoTheme.Spacing.xl)
            }

            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Yeni Ürün Ekle")
                        .font(MenuLoTheme.Fonts.button)
                }
                .foregroundColor(.white)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(MenuLoTheme.Spacing.lg)
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
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, MenuLoTheme.Spacing.sm)
                .background(
                    isSelected
                        ? AnyView(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                                startPoint: .leading, endPoint: .trailing
                            )
                          )
                        : AnyView(MenuLoTheme.Colors.cardBackground)
                )
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : MenuLoTheme.Colors.divider,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? MenuLoTheme.Colors.primary.opacity(0.3) : .primary.opacity(0.04),
                    radius: 5
                )
        }
    }
}

// MARK: - Add Sheet
struct AddMenuItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSubmit: (OwnerMenuItemPayload) -> Void

    @State private var name        = ""
    @State private var category    = "Pizza"
    @State private var price       = ""
    @State private var description = ""
    @State private var isGreenMenu = false
    @State private var isAvailable = true

    let categories = ["Pizza", "Burger", "Salata", "Çorba", "Ana Yemek", "Tatlı", "İçecek"]

    var isFormValid: Bool { !name.isEmpty && !price.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    FormSection(title: "Ürün Bilgileri") {
                        CustomTextField(placeholder: "Ürün Adı", iconName: "tag.fill", text: $name)
                        CustomTextField(placeholder: "Fiyat (₺)", iconName: "turkishlirasign.circle.fill", text: $price)
                            .keyboardType(.decimalPad)
                        CustomTextField(placeholder: "Kısa açıklama (opsiyonel)", iconName: "text.alignleft", text: $description)

                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Picker("Kategori", selection: $category) {
                                ForEach(categories, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(MenuLoTheme.Colors.primary)
                            Spacer()
                        }
                        .padding()
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        .shadow(color: .primary.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    VStack(spacing: MenuLoTheme.Spacing.md) {
                        ToggleCard(
                            title: "Aktif",
                            subtitle: "Müşteri menüsünde göster",
                            icon: "checkmark.circle.fill",
                            tint: MenuLoTheme.Colors.success,
                            isOn: $isAvailable
                        )

                        ToggleCard(
                            title: "Yeşil Menü Ürünü",
                            subtitle: "Gıda israfı önleme — indirimli sun",
                            icon: "leaf.fill",
                            tint: MenuLoTheme.Colors.success,
                            isOn: $isGreenMenu,
                            highlightWhenOn: true
                        )
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    PrimaryButton(title: "Ürünü Kaydet") {
                        let payload = OwnerMenuItemPayload(
                            name: name,
                            price: Double(price) ?? 0,
                            description: description.isEmpty ? nil : description,
                            category: category,
                            isGreenMenu: isGreenMenu,
                            isAvailable: isAvailable
                        )
                        onSubmit(payload)
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
}

// MARK: - Edit Sheet
struct EditMenuItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: OwnerMenuItem
    let onUpdate: (OwnerMenuItemPayload) -> Void
    let onDelete: () -> Void

    @State private var name: String
    @State private var description: String
    @State private var price: String
    @State private var category: String
    @State private var isAvailable: Bool
    @State private var isGreenMenu: Bool
    @State private var showDeleteConfirm = false

    let categories = ["Pizza", "Burger", "Salata", "Çorba", "Ana Yemek", "Tatlı", "İçecek"]

    init(item: OwnerMenuItem,
         onUpdate: @escaping (OwnerMenuItemPayload) -> Void,
         onDelete: @escaping () -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        _name        = State(initialValue: item.name)
        _description = State(initialValue: item.description ?? "")
        _price       = State(initialValue: String(format: "%.0f", item.price))
        _category    = State(initialValue: item.category)
        _isAvailable = State(initialValue: item.isAvailable)
        _isGreenMenu = State(initialValue: item.isGreenMenu)
    }

    var isFormValid: Bool { !name.isEmpty && !price.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        Text(emoji)
                            .font(.system(size: 36))
                            .frame(width: 56, height: 56)
                            .background(MenuLoTheme.Colors.primary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ürünü Düzenle")
                                .font(MenuLoTheme.Fonts.subtitle)
                                .foregroundColor(.primary)
                            Text(item.category)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.top, MenuLoTheme.Spacing.md)

                    FormSection(title: "Ürün Bilgileri") {
                        CustomTextField(placeholder: "Ürün Adı", iconName: "tag.fill", text: $name)
                        CustomTextField(placeholder: "Fiyat (₺)", iconName: "turkishlirasign.circle.fill", text: $price)
                            .keyboardType(.decimalPad)
                        CustomTextField(placeholder: "Açıklama (opsiyonel)", iconName: "text.alignleft", text: $description)

                        HStack {
                            Image(systemName: "square.grid.2x2.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 24)
                            Picker("Kategori", selection: $category) {
                                ForEach(categories, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(MenuLoTheme.Colors.primary)
                            Spacer()
                        }
                        .padding()
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        .shadow(color: .primary.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    VStack(spacing: MenuLoTheme.Spacing.md) {
                        ToggleCard(
                            title: "Aktif",
                            subtitle: "Müşteri menüsünde göster",
                            icon: "checkmark.circle.fill",
                            tint: MenuLoTheme.Colors.success,
                            isOn: $isAvailable
                        )

                        ToggleCard(
                            title: "Yeşil Menü",
                            subtitle: "Gıda israfı önleme — indirimli sun",
                            icon: "leaf.fill",
                            tint: MenuLoTheme.Colors.success,
                            isOn: $isGreenMenu,
                            highlightWhenOn: true
                        )
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    VStack(spacing: MenuLoTheme.Spacing.sm) {
                        PrimaryButton(title: "Güncelle") {
                            let payload = OwnerMenuItemPayload(
                                name: name,
                                price: Double(price) ?? item.price,
                                description: description.isEmpty ? nil : description,
                                category: category,
                                isGreenMenu: isGreenMenu,
                                isAvailable: isAvailable
                            )
                            onUpdate(payload)
                            dismiss()
                        }
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1 : 0.5)

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Ürünü Sil")
                                    .font(MenuLoTheme.Fonts.button)
                            }
                            .foregroundColor(MenuLoTheme.Colors.error)
                            .frame(maxWidth: .infinity)
                            .padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.error.opacity(0.08))
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                    .strokeBorder(MenuLoTheme.Colors.error.opacity(0.25), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.sm)
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .navigationTitle("Ürün Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
            .alert("Ürünü Sil", isPresented: $showDeleteConfirm) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("\"\(item.name)\" menüden kaldırılacak. Emin misin?")
            }
        }
    }

    private var emoji: String {
        switch item.category {
        case "Pizza":     return "🍕"
        case "Burger":    return "🍔"
        case "Salata":    return "🥗"
        case "Çorba":     return "🍲"
        case "Ana Yemek": return "🍗"
        case "Tatlı":     return "🍰"
        case "İçecek":    return "🥤"
        default:          return "🍽️"
        }
    }
}

// MARK: - Reusable Toggle Card
private struct ToggleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    @Binding var isOn: Bool
    var highlightWhenOn: Bool = false

    var body: some View {
        Toggle(isOn: $isOn.animation()) {
            HStack(spacing: MenuLoTheme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .tint(tint)
        .padding(MenuLoTheme.Spacing.md)
        .background(highlightWhenOn && isOn
                    ? tint.opacity(0.08)
                    : MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                .strokeBorder(
                    highlightWhenOn && isOn ? tint.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .shadow(color: .primary.opacity(0.04), radius: 5)
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
                .foregroundColor(.secondary)
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

// MARK: - Preview
#Preview {
    NavigationStack {
        MenuManagerView(restaurantId: 1)
            .environmentObject(AuthViewModel())
    }
}
