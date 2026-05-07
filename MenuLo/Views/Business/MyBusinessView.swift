//
//  MyBusinessView.swift
//  MenuLo
//
//  MenuLo/Views/Business/MyBusinessView.swift
//
//  İşletme sahibinin kendi işletme profilini yönettiği ekran.
//  Vitrin: işletme adı, mutfak tipi, adres, çalışma saatleri.
//

import SwiftUI

struct MyBusinessView: View {

    // MARK: - Düzenlenebilir Alanlar (Mock Veri)
    @State private var businessName  = "Lezzet Durağı"
    @State private var businessDesc  = "Kadıköy'ün kalbinde, taze malzemelerle hazırlanan el yapımı pizza ve burger çeşitlerimizle hizmetinizdeyiz."
    @State private var address       = "Moda Caddesi No:42, Kadıköy, İstanbul"
    @State private var phone         = "+90 216 555 01 23"
    @State private var website       = "www.lezzetduragi.com"
    @State private var cuisineType   = "Türk & Dünya Mutfağı"

    // Konum (mock — ileride gerçek koordinat picker eklenebilir)
    @State private var latitude:  Double = 40.987
    @State private var longitude: Double = 29.025

    // Çalışma saatleri
    @State private var openHour  = 9
    @State private var openMin   = 0
    @State private var closeHour = 22
    @State private var closeMin  = 0
    @State private var showSaveAlert = false
    @State private var isLoading     = false

    @State private var openDays: [String: Bool] = [
        "Pazartesi": true,  "Salı": true,  "Çarşamba": true,
        "Perşembe": true,   "Cuma": true,  "Cumartesi": true,
        "Pazar": false
    ]
    let dayOrder = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    let cuisineOptions = [
        "Türk Mutfağı", "Türk & Dünya Mutfağı", "Pizza & Burger",
        "Sushi & Asya", "Kahvaltı", "Vegan / Vegetaryan",
        "Tatlı & Pastane", "Kahve & İçecek"
    ]

    // Mock istatistikler
    private let stats: [(icon: String, label: String, value: String, color: Color)] = [
        ("eye.fill",    "Görüntülenme",  "1.2K", Color(hex: "#6C5CE7")),
        ("star.fill",   "Puan",          "4.7",  Color(hex: "#FDCB6E")),
        ("heart.fill",  "Favori",        "248",  Color(hex: "#E17055")),
        ("leaf.fill",   "Yeşil Menü",    "3",    MenuLoTheme.Colors.success),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Hero / Cover
                MyBusinessHero(name: businessName, location: address, cuisine: cuisineType)

                // Avatar overflow için boşluk
                Spacer().frame(height: 24)

                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // MARK: - İstatistikler
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()),
                                  GridItem(.flexible()), GridItem(.flexible())],
                        spacing: MenuLoTheme.Spacing.sm
                    ) {
                        ForEach(stats, id: \.label) { stat in
                            StatCard(icon: stat.icon, label: stat.label,
                                     value: stat.value, color: stat.color)
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // MARK: - İşletme Bilgileri
                    BusinessSection(title: "İşletme Bilgileri", icon: "info.circle.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            EditableField(label: "Restoran Adı",  icon: "building.2", text: $businessName)

                            // Mutfak Tipi (picker)
                            CuisinePickerRow(selection: $cuisineType, options: cuisineOptions)

                            EditableField(label: "Adres",     icon: "mappin",   text: $address)
                            EditableField(label: "Telefon",   icon: "phone",    text: $phone)
                            EditableField(label: "Web Sitesi", icon: "globe",   text: $website)

                            // Açıklama
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Açıklama", systemImage: "text.alignleft")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(.secondary)
                                TextEditor(text: $businessDesc)
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(.primary)
                                    .frame(minHeight: 80)
                                    .padding(MenuLoTheme.Spacing.sm)
                                    .background(Color(.tertiarySystemFill))
                                    .cornerRadius(MenuLoTheme.CornerRadius.medium)
                                    .scrollContentBackground(.hidden)
                            }
                        }
                    }

                    // MARK: - Konum
                    BusinessSection(title: "Harita Konumu", icon: "map.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            HStack(spacing: MenuLoTheme.Spacing.md) {
                                CoordinateField(label: "Enlem",  value: $latitude)
                                CoordinateField(label: "Boylam", value: $longitude)
                            }

                            Label("Müşteriler bu koordinatta haritada görür. Sürükle-yerleştir map seçici yakında.",
                                  systemImage: "info.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.top, 4)
                        }
                    }

                    // MARK: - Çalışma Saatleri
                    BusinessSection(title: "Çalışma Saatleri", icon: "clock.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            HStack(spacing: MenuLoTheme.Spacing.md) {
                                TimePickerCard(
                                    label: "Açılış",
                                    icon: "sunrise.fill",
                                    color: MenuLoTheme.Colors.success,
                                    hour: $openHour, minute: $openMin
                                )
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.secondary)
                                TimePickerCard(
                                    label: "Kapanış",
                                    icon: "sunset.fill",
                                    color: MenuLoTheme.Colors.error,
                                    hour: $closeHour, minute: $closeMin
                                )
                            }

                            Divider()

                            VStack(spacing: 0) {
                                ForEach(Array(dayOrder.enumerated()), id: \.element) { idx, day in
                                    HStack {
                                        Text(day)
                                            .font(MenuLoTheme.Fonts.body)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if openDays[day] == true {
                                            Text(String(format: "%02d:%02d – %02d:%02d",
                                                        openHour, openMin, closeHour, closeMin))
                                                .font(MenuLoTheme.Fonts.caption)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text("Kapalı")
                                                .font(MenuLoTheme.Fonts.caption)
                                                .foregroundColor(MenuLoTheme.Colors.error)
                                        }
                                        Toggle("", isOn: Binding(
                                            get: { openDays[day] ?? false },
                                            set: { openDays[day] = $0 }
                                        ))
                                        .tint(MenuLoTheme.Colors.primary)
                                        .labelsHidden()
                                        .scaleEffect(0.8)
                                    }
                                    .padding(.vertical, 6)
                                    if idx < dayOrder.count - 1 { Divider() }
                                }
                            }
                        }
                    }

                    // MARK: - Kaydet
                    PrimaryButton(title: "Değişiklikleri Kaydet", isLoading: isLoading) {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            isLoading = false
                            showSaveAlert = true
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xxl)
                }
                .padding(.top, MenuLoTheme.Spacing.lg)
            }
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Dükkanım")
        .navigationBarTitleDisplayMode(.large)
        .alert("Kaydedildi ✅", isPresented: $showSaveAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("İşletme bilgileriniz başarıyla güncellendi.")
        }
    }
}

// MARK: - Hero (cover + emoji avatar + ad/lokasyon)
private struct MyBusinessHero: View {
    let name: String
    let location: String
    let cuisine: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            MenuLoTheme.Colors.primary.opacity(0.85),
                            Color(hex: "#FF6B35").opacity(0.95)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 170)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.12))
                        .offset(x: 100, y: 30)
                )

            HStack(alignment: .bottom, spacing: MenuLoTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(MenuLoTheme.Colors.cardBackground)
                        .frame(width: 76, height: 76)
                        .shadow(color: .primary.opacity(0.18), radius: 8, x: 0, y: 4)
                    Text("🍕")
                        .font(.system(size: 38))
                }
                .offset(y: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(MenuLoTheme.Fonts.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text(cuisine)
                            .font(MenuLoTheme.Fonts.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, MenuLoTheme.Spacing.sm)

                Spacer()
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .padding(.bottom, MenuLoTheme.Spacing.md)
        }
    }
}

// MARK: - Cuisine Picker
private struct CuisinePickerRow: View {
    @Binding var selection: String
    let options: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Mutfak Tipi", systemImage: "fork.knife")
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "leaf.circle.fill")
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .frame(width: 24)
                Picker("Mutfak Tipi", selection: $selection) {
                    ForEach(options, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .tint(.primary)
                Spacer()
            }
            .padding(MenuLoTheme.Spacing.md)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(MenuLoTheme.CornerRadius.medium)
        }
    }
}

private struct CoordinateField: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.secondary)
            TextField(label, value: $value, format: .number.precision(.fractionLength(4)))
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.primary)
                .keyboardType(.decimalPad)
                .padding(MenuLoTheme.Spacing.md)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(MenuLoTheme.CornerRadius.medium)
        }
    }
}

// MARK: - Yardımcı Bileşenler
private struct StatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(value)
                .font(MenuLoTheme.Fonts.subtitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .primary.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct EditableField: View {
    let label: String
    let icon: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(.secondary)
            TextField(label, text: $text)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.primary)
                .padding(MenuLoTheme.Spacing.md)
                .background(Color(.tertiarySystemFill))
                .cornerRadius(MenuLoTheme.CornerRadius.medium)
        }
    }
}

private struct TimePickerCard: View {
    let label: String
    let icon: String
    let color: Color
    @Binding var hour: Int
    @Binding var minute: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(label)
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Picker("Saat", selection: $hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50, height: 70)
                .clipped()

                Text(":")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(.primary)

                Picker("Dakika", selection: $minute) {
                    ForEach([0, 15, 30, 45], id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50, height: 70)
                .clipped()
            }
            .background(Color(.tertiarySystemFill))
            .cornerRadius(MenuLoTheme.CornerRadius.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(MenuLoTheme.Spacing.md)
        .background(color.opacity(0.08))
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct BusinessSection<Content: View>: View {
    let title: String
    let icon: String
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
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: 0) {
                content
            }
            .padding(MenuLoTheme.Spacing.lg)
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .primary.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        MyBusinessView()
    }
}
