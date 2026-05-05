//
//  RoomListView.swift
//  MenuLo
//
//  MenuLo/Views/Room/RoomListView.swift
//
//  Grup Karar Odası — Arkadaş gruplarıyla ortak yemek kararı.
//  Oda oluşturma: yemek kategorisi butonları + ortak bütçe + Max Distance slider.
//

import SwiftUI

// MARK: - Mock Oda Modeli
private struct DecisionRoom: Identifiable {
    let id = UUID()
    let name: String
    let host: String
    let participants: Int
    let categories: [String]
    let budget: Int
    let maxDistance: Int  // km
    let status: String    // "active", "deciding", "done"
    let emoji: String
}

// MARK: - RoomListView
struct RoomListView: View {

    @State private var showCreateSheet = false
    @State private var showJoinSheet   = false
    @State private var joinCode        = ""

    private let mockRooms: [DecisionRoom] = [
        DecisionRoom(name: "Cuma Akşamı 🍕", host: "Selin T.", participants: 4, categories: ["Pizza", "Burger"], budget: 150, maxDistance: 3, status: "deciding", emoji: "🍕"),
        DecisionRoom(name: "Öğle Yemeği Kararı", host: "Mert A.", participants: 3, categories: ["Salad", "Sushi"], budget: 100, maxDistance: 1, status: "active", emoji: "🥗"),
        DecisionRoom(name: "Doğum Günü Akşamı", host: "Zeynep B.", participants: 6, categories: ["Steak", "Pizza"], budget: 250, maxDistance: 5, status: "done", emoji: "🎂"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: - Header Aksiyon Butonları
                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        // Oda Oluştur
                        Button {
                            showCreateSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Oda Oluştur")
                                    .font(MenuLoTheme.Fonts.button)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.primary)
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 8)
                        }

                        // Odaya Katıl
                        Button {
                            showJoinSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title3)
                                Text("Katıl")
                                    .font(MenuLoTheme.Fonts.button)
                            }
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .frame(maxWidth: .infinity)
                            .padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.primary.opacity(0.1))
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                    .strokeBorder(MenuLoTheme.Colors.primary.opacity(0.4), lineWidth: 1.5)
                            )
                        }
                    }
                    .padding(MenuLoTheme.Spacing.lg)

                    // MARK: - Aktif Odalar
                    if mockRooms.isEmpty {
                        Spacer()
                        emptyState
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: MenuLoTheme.Spacing.md) {
                                ForEach(mockRooms) { room in
                                    RoomCard(room: room)
                                }
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                            .padding(.bottom, MenuLoTheme.Spacing.xl)
                        }
                    }
                }
            }
            .navigationTitle("Karar Odaları")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateSheet) {
                CreateRoomSheet()
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinRoomSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 64))
                .foregroundColor(MenuLoTheme.Colors.primary)
            Text("Henüz oda yok")
                .font(MenuLoTheme.Fonts.title)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Text("Arkadaşlarınla oda oluştur veya bir odaya katıl.")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, MenuLoTheme.Spacing.xl)
    }
}

// MARK: - Oda Kartı
private struct RoomCard: View {
    let room: DecisionRoom

    var statusColor: Color {
        switch room.status {
        case "active":   return MenuLoTheme.Colors.success
        case "deciding": return MenuLoTheme.Colors.primary
        case "done":     return MenuLoTheme.Colors.textSecondary
        default:         return MenuLoTheme.Colors.textSecondary
        }
    }
    var statusLabel: String {
        switch room.status {
        case "active":   return "Aktif"
        case "deciding": return "Karar Veriliyor"
        case "done":     return "Tamamlandı"
        default:         return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack {
                Text(room.emoji)
                    .font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Text("Oluşturan: \(room.host)")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
                Spacer()
                // Durum rozeti
                Text(statusLabel)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            // Kategoriler
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(room.categories, id: \.self) { cat in
                        Text(cat)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(MenuLoTheme.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }

            HStack {
                // Katılımcılar
                Label("\(room.participants) kişi", systemImage: "person.2.fill")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                Spacer()

                // Bütçe
                Label("₺\(room.budget)/kişi", systemImage: "turkishlirasign.circle")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                Spacer()

                // Mesafe
                Label("\(room.maxDistance) km", systemImage: "location.circle")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Oda Oluşturma Sheet
struct CreateRoomSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var roomName    = ""
    @State private var budget: Double = 100
    @State private var maxDistance: Double = 3
    @State private var selectedCategories: Set<String> = []
    @State private var isCreating = false

    let foodCategories: [(name: String, emoji: String)] = [
        ("Pizza", "🍕"), ("Hamburger", "🍔"), ("Salad", "🥗"),
        ("Sushi", "🍣"), ("Steak", "🥩"), ("Döner", "🌯"),
        ("Pasta", "🍝"), ("Soup", "🍲"), ("Dessert", "🍰"),
        ("Seafood", "🦐"), ("Ramen", "🍜"), ("Vegan", "🌱"),
    ]

    var isFormValid: Bool {
        !roomName.isEmpty && !selectedCategories.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // --- Oda Adı ---
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
                        SectionHeader(title: "Oda Bilgileri", icon: "door.left.hand.open")
                        CustomTextField(
                            placeholder: "Oda Adı (örn: Cuma Akşamı)",
                            iconName: "pencil",
                            text: $roomName
                        )
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // --- Yemek Kategorileri ---
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
                        SectionHeader(title: "Yemek Kategorileri", icon: "fork.knife")
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        Text("En az 1 kategori seç")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                            spacing: MenuLoTheme.Spacing.sm
                        ) {
                            ForEach(foodCategories, id: \.name) { cat in
                                FoodCategoryButton(
                                    name: cat.name,
                                    emoji: cat.emoji,
                                    isSelected: selectedCategories.contains(cat.name)
                                ) {
                                    withAnimation(.spring(response: 0.2)) {
                                        if selectedCategories.contains(cat.name) {
                                            selectedCategories.remove(cat.name)
                                        } else {
                                            selectedCategories.insert(cat.name)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // --- Ortak Bütçe ---
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
                        SectionHeader(title: "Ortak Bütçe", icon: "turkishlirasign.circle.fill")
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            HStack {
                                Text("₺\(Int(budget))")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                                Text("/ kişi")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                    .padding(.top, 8)
                                Spacer()
                            }

                            Slider(value: $budget, in: 50...1000, step: 25)
                                .tint(MenuLoTheme.Colors.primary)

                            HStack {
                                Text("₺50")
                                Spacer()
                                Text("₺1000")
                            }
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                        .padding(MenuLoTheme.Spacing.lg)
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // --- Max Distance ---
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
                        SectionHeader(title: "Max Distance", icon: "location.circle.fill")
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            HStack {
                                Text("\(String(format: "%.0f", maxDistance)) km")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "#6C5CE7"))
                                Text("maks. uzaklık")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                    .padding(.top, 8)
                                Spacer()
                            }

                            Slider(value: $maxDistance, in: 0.5...20, step: 0.5)
                                .tint(Color(hex: "#6C5CE7"))

                            HStack {
                                Text("0.5 km")
                                Spacer()
                                Text("20 km")
                            }
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                        .padding(MenuLoTheme.Spacing.lg)
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // --- Oluştur Butonu ---
                    PrimaryButton(title: "Odayı Oluştur", isLoading: isCreating) {
                        isCreating = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isCreating = false
                            dismiss()
                        }
                    }
                    .disabled(!isFormValid)
                    .opacity(isFormValid ? 1 : 0.5)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Oda Oluştur")
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

// MARK: - Odaya Katılma Sheet
struct JoinRoomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: MenuLoTheme.Spacing.xl) {
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 64))
                        .foregroundColor(MenuLoTheme.Colors.primary)

                    Text("Odaya Katıl")
                        .font(MenuLoTheme.Fonts.largeTitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    Text("QR kodu tara veya oda kodunu gir")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
                .padding(.top, MenuLoTheme.Spacing.xl)

                CustomTextField(placeholder: "Oda Kodu (örn: ABC-1234)", iconName: "key.fill", text: $code)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                PrimaryButton(title: "Katıl") {
                    dismiss()
                }
                .disabled(code.isEmpty)
                .opacity(code.isEmpty ? 0.5 : 1)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                Spacer()
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
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

// MARK: - Yardımcı Bileşenler
private struct FoodCategoryButton: View {
    let name: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 28))
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MenuLoTheme.Spacing.sm)
            .background(
                isSelected
                    ? MenuLoTheme.Colors.primary
                    : MenuLoTheme.Colors.cardBackground
            )
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .strokeBorder(
                        isSelected ? Color.clear : MenuLoTheme.Colors.divider,
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: isSelected ? MenuLoTheme.Colors.primary.opacity(0.35) : .clear,
                radius: 6
            )
        }
    }
}

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(MenuLoTheme.Colors.primary)
                .font(.footnote)
            Text(title)
                .font(MenuLoTheme.Fonts.subtitle)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    RoomListView()
}
