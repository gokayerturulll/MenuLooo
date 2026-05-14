import SwiftUI

// MARK: - RoomListView

struct RoomListView: View {

    @EnvironmentObject private var viewModel: RoomViewModel
    @State private var showCreateSheet   = false
    @State private var showJoinSheet     = false
    @State private var showActiveRoom    = false

    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

                VStack(spacing: 0) {

                    // MARK: Aksiyon Butonları
                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        Button { showCreateSheet = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill").font(.title3)
                                Text("Oda Oluştur").font(MenuLoTheme.Fonts.button)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.primary)
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 8)
                        }

                        Button { showJoinSheet = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "qrcode.viewfinder").font(.title3)
                                Text("Katıl").font(MenuLoTheme.Fonts.button)
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

                    // MARK: Aktif oda kartı (varsa)
                    if let room = viewModel.currentRoom {
                        ActiveRoomBanner(
                            room: room,
                            participantCount: viewModel.participantIds.count,
                            isSocketConnected: viewModel.isSocketConnected
                        ) {
                            showActiveRoom = true
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, MenuLoTheme.Spacing.md)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // MARK: Geçmiş / mock odalar
                    ScrollView {
                        LazyVStack(spacing: MenuLoTheme.Spacing.md) {
                            ForEach(mockRooms) { room in RoomCard(room: room) }
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, MenuLoTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Karar Odaları")
            .navigationBarTitleDisplayMode(.large)
            .animation(.spring(response: 0.35), value: viewModel.currentRoom?.roomId)
            .sheet(isPresented: $showCreateSheet) {
                CreateRoomSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinRoomSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showActiveRoom) {
                if let room = viewModel.currentRoom {
                    ActiveRoomView(
                        room: room,
                        participantIds: viewModel.participantIds,
                        onLeave: { viewModel.leaveCurrentRoom() }
                    )
                }
            }
        }
    }

    // MARK: Mock geçmiş odalar (ileri fazda API'den gelecek)
    private let mockRooms: [MockRoom] = [
        MockRoom(name: "Cuma Akşamı 🍕", host: "Selin T.", participants: 4,
                 categories: ["Pizza", "Burger"], budget: 150, maxDistance: 3, status: "deciding", emoji: "🍕"),
        MockRoom(name: "Öğle Yemeği Kararı", host: "Mert A.", participants: 3,
                 categories: ["Salad", "Sushi"], budget: 100, maxDistance: 1, status: "active", emoji: "🥗"),
        MockRoom(name: "Doğum Günü Akşamı", host: "Zeynep B.", participants: 6,
                 categories: ["Steak", "Pizza"], budget: 250, maxDistance: 5, status: "done", emoji: "🎂"),
    ]
}

// MARK: - Aktif Oda Banner

private struct ActiveRoomBanner: View {
    let room: Room
    let participantCount: Int
    let isSocketConnected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: MenuLoTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(room.name)
                        .font(MenuLoTheme.Fonts.body).fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isSocketConnected ? MenuLoTheme.Colors.success : .gray)
                            .frame(width: 8, height: 8)
                        Text(isSocketConnected ? "Canlı" : "Bağlanıyor...")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }

                Spacer()

                // PIN etiketi — arkadaşlar bu kodu kullanarak katılır
                VStack(spacing: 2) {
                    Text("PIN")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    Text(room.pinCode)
                        .font(.system(.title3, design: .monospaced)).fontWeight(.bold)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(MenuLoTheme.Colors.primary.opacity(0.08))
                .cornerRadius(MenuLoTheme.CornerRadius.large)

                Image(systemName: "chevron.right")
                    .font(.footnote).foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .padding(MenuLoTheme.Spacing.md)
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.12), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Aktif Oda Sayfası (PIN + katılımcılar)

struct ActiveRoomView: View {
    let room: Room
    let participantIds: [Int]
    let onLeave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MenuLoTheme.Spacing.xl) {

                // PIN Kutusu
                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    Text("Oda PIN'i")
                        .font(MenuLoTheme.Fonts.subtitle)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)

                    Text(room.pinCode)
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                        .tracking(8)

                    Text("Arkadaşlarını davet etmek için bu kodu paylaş")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(MenuLoTheme.Spacing.xl)
                .frame(maxWidth: .infinity)
                .background(MenuLoTheme.Colors.cardBackground)
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.1), radius: 10)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                // Gerçek QR Kod — CoreImage ile üretildi
                if let qr = RoomViewModel.generateQRImage(for: room.pinCode) {
                    Image(uiImage: qr)
                        .interpolation(.none)       // piksel bozulmasını önler
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(MenuLoTheme.Spacing.md)
                        .background(Color.white)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .shadow(color: .black.opacity(0.08), radius: 8)
                } else {
                    Image(systemName: "qrcode")
                        .font(.system(size: 80))
                        .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.3))
                }

                // Katılımcı sayısı
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    Text("\(participantIds.count) katılımcı")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                }

                Spacer()

                // Odadan Ayrıl
                Button {
                    onLeave()
                    dismiss()
                } label: {
                    Text("Odadan Ayrıl")
                        .font(MenuLoTheme.Fonts.button)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(MenuLoTheme.Spacing.md)
                        .background(Color.red.opacity(0.08))
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.bottom, MenuLoTheme.Spacing.xl)
            }
            .padding(.top, MenuLoTheme.Spacing.lg)
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .navigationTitle(room.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Oda Oluşturma Sheet

struct CreateRoomSheet: View {
    @ObservedObject var viewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var roomName           = ""
    @State private var budget: Double     = 100
    @State private var maxDistance: Double = 3
    @State private var selectedCategories: Set<String> = []

    let foodCategories: [(name: String, emoji: String)] = [
        ("Pizza", "🍕"), ("Hamburger", "🍔"), ("Salad", "🥗"),
        ("Sushi", "🍣"), ("Steak", "🥩"), ("Döner", "🌯"),
        ("Pasta", "🍝"), ("Soup", "🍲"), ("Dessert", "🍰"),
        ("Seafood", "🦐"), ("Ramen", "🍜"), ("Vegan", "🌱"),
    ]

    var isFormValid: Bool { !roomName.isEmpty && !selectedCategories.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // Hata mesajı
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // Oda Adı
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
                        SectionHeader(title: "Oda Bilgileri", icon: "door.left.hand.open")
                        CustomTextField(
                            placeholder: "Oda Adı (örn: Cuma Akşamı)",
                            iconName: "pencil",
                            text: $roomName
                        )
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // Kategoriler
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
                                    name: cat.name, emoji: cat.emoji,
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

                    // Bütçe
                    SliderCard(
                        title: "Ortak Bütçe", icon: "turkishlirasign.circle.fill",
                        valueLabel: "₺\(Int(budget)) / kişi",
                        value: $budget, range: 50...1000, step: 25,
                        minLabel: "₺50", maxLabel: "₺1000",
                        tint: MenuLoTheme.Colors.primary
                    )

                    // Max Mesafe
                    SliderCard(
                        title: "Max Mesafe", icon: "location.circle.fill",
                        valueLabel: "\(String(format: "%.1f", maxDistance)) km",
                        value: $maxDistance, range: 0.5...20, step: 0.5,
                        minLabel: "0.5 km", maxLabel: "20 km",
                        tint: Color(hex: "#6C5CE7")
                    )

                    // Oluştur Butonu
                    PrimaryButton(title: "Odayı Oluştur", isLoading: viewModel.isLoading) {
                        Task {
                            await viewModel.createRoom(
                                name: roomName,
                                categories: Array(selectedCategories),
                                budget: Int(budget),
                                maxDistanceKm: maxDistance
                            )
                            if viewModel.currentRoom != nil { dismiss() }
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
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
    @ObservedObject var viewModel: RoomViewModel
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

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }

                CustomTextField(
                    placeholder: "Oda Kodu (örn: A3F9C2)",
                    iconName: "key.fill",
                    text: $code
                )
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                PrimaryButton(title: "Katıl", isLoading: viewModel.isLoading) {
                    Task {
                        await viewModel.joinRoom(pinCode: code.uppercased())
                        if viewModel.currentRoom != nil { dismiss() }
                    }
                }
                .disabled(code.isEmpty || viewModel.isLoading)
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

private struct SliderCard: View {
    let title: String
    let icon: String
    let valueLabel: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let minLabel: String
    let maxLabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            SectionHeader(title: title, icon: icon)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: MenuLoTheme.Spacing.sm) {
                HStack {
                    Text(valueLabel)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(tint)
                    Spacer()
                }
                Slider(value: $value, in: range, step: step).tint(tint)
                HStack {
                    Text(minLabel)
                    Spacer()
                    Text(maxLabel)
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
    }
}

private struct FoodCategoryButton: View {
    let name: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 28))
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MenuLoTheme.Spacing.sm)
            .background(isSelected ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.cardBackground)
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

// MARK: - Mock Model (geçici; ileri fazda API listesi geçecek)

private struct MockRoom: Identifiable {
    let id = UUID()
    let name: String
    let host: String
    let participants: Int
    let categories: [String]
    let budget: Int
    let maxDistance: Int
    let status: String
    let emoji: String
}

private struct RoomCard: View {
    let room: MockRoom

    var statusColor: Color {
        switch room.status {
        case "active":   return MenuLoTheme.Colors.success
        case "deciding": return MenuLoTheme.Colors.primary
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
                Text(room.emoji).font(.system(size: 32))
                VStack(alignment: .leading, spacing: 2) {
                    Text(room.name)
                        .font(MenuLoTheme.Fonts.body).fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Text("Oluşturan: \(room.host)")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
                Spacer()
                Text(statusLabel)
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(room.categories, id: \.self) { cat in
                        Text(cat)
                            .font(.caption2).foregroundColor(.white)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(MenuLoTheme.Colors.primary).clipShape(Capsule())
                    }
                }
            }

            HStack {
                Label("\(room.participants) kişi", systemImage: "person.2.fill")
                Spacer()
                Label("₺\(room.budget)/kişi", systemImage: "turkishlirasign.circle")
                Spacer()
                Label("\(room.maxDistance) km", systemImage: "location.circle")
            }
            .font(MenuLoTheme.Fonts.caption)
            .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    RoomListView()
        .environmentObject(RoomViewModel())
}
