//
//  MyBusinessView.swift
//  MenuLo
//
//  MenuLo/Views/Business/MyBusinessView.swift
//
//  İşletme sahibinin kendi işletme profilini yönettiği ekran.
//  İşletme adı, konum, açıklama ve çalışma saatlerini düzenleyebilir.
//

import SwiftUI

struct MyBusinessView: View {
    
    // MARK: - Düzenlenebilir Alanlar (Mock Veri)
    @State private var businessName  = "Lezzet Durağı"
    @State private var businessDesc  = "Kadıköy'ün kalbinde, taze malzemelerle hazırlanan el yapımı pizza ve burger çeşitlerimizle hizmetinizdeyiz."
    @State private var address       = "Moda Caddesi No:42, Kadıköy, İstanbul"
    @State private var phone         = "+90 216 555 01 23"
    @State private var website       = "www.lezzetduragi.com"

    // Çalışma Saatleri
    @State private var openHour  = 9
    @State private var openMin   = 0
    @State private var closeHour = 22
    @State private var closeMin  = 0
    
    @State private var isEditingHours  = false
    @State private var showSaveAlert   = false
    @State private var isLoading       = false

    // Günler bazlı açık/kapalı
    @State private var openDays: [String: Bool] = [
        "Pazartesi": true,  "Salı": true,  "Çarşamba": true,
        "Perşembe": true,   "Cuma": true,  "Cumartesi": true,
        "Pazar": false
    ]
    let dayOrder = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    // MARK: - Mock Stats
    private let stats: [(icon: String, label: String, value: String, color: Color)] = [
        ("eye.fill",          "Görüntülenme",   "1.2K",  Color(hex: "#6C5CE7")),
        ("star.fill",         "Ortalama Puan",  "4.7",   Color(hex: "#FDCB6E")),
        ("heart.fill",        "Favori",         "248",   Color(hex: "#E17055")),
        ("leaf.fill",         "Yeşil Menü",     "3",     Color(hex: "#00B894")),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // MARK: - Hero / Cover
                    ZStack(alignment: .bottomLeading) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        MenuLoTheme.Colors.primary.opacity(0.8),
                                        Color(hex: "#FF6B35").opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 160)
                            .overlay(
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.15))
                                    .offset(x: 60, y: 20)
                            )

                        HStack(alignment: .bottom, spacing: MenuLoTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 72, height: 72)
                                    .shadow(radius: 6)
                                Text("🍕")
                                    .font(.system(size: 36))
                            }
                            .offset(y: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(businessName)
                                    .font(MenuLoTheme.Fonts.title)
                                    .foregroundColor(.white)
                                    .fontWeight(.bold)
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    Text("Kadıköy, İstanbul")
                                        .font(MenuLoTheme.Fonts.caption)
                                }
                                .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.bottom, MenuLoTheme.Spacing.sm)
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, MenuLoTheme.Spacing.md)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 0))

                    // Padding for avatar overflow
                    Spacer().frame(height: 12)

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
                            EditableField(label: "İşletme Adı",  icon: "building.2",     text: $businessName)
                            EditableField(label: "Adres",         icon: "mappin",          text: $address)
                            EditableField(label: "Telefon",       icon: "phone",           text: $phone)
                            EditableField(label: "Web Sitesi",    icon: "globe",           text: $website)

                            // Açıklama
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Açıklama", systemImage: "text.alignleft")
                                    .font(MenuLoTheme.Fonts.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                TextEditor(text: $businessDesc)
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                    .frame(minHeight: 80)
                                    .padding(MenuLoTheme.Spacing.sm)
                                    .background(MenuLoTheme.Colors.backgroundLight)
                                    .cornerRadius(MenuLoTheme.CornerRadius.medium)
                            }
                        }
                    }

                    // MARK: - Çalışma Saatleri
                    BusinessSection(title: "Çalışma Saatleri", icon: "clock.fill") {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            // Açılış / Kapanış
                            HStack(spacing: MenuLoTheme.Spacing.md) {
                                TimePickerCard(
                                    label: "Açılış",
                                    icon: "sunrise.fill",
                                    color: MenuLoTheme.Colors.success,
                                    hour: $openHour,
                                    minute: $openMin
                                )
                                Image(systemName: "arrow.right")
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                TimePickerCard(
                                    label: "Kapanış",
                                    icon: "sunset.fill",
                                    color: MenuLoTheme.Colors.error,
                                    hour: $closeHour,
                                    minute: $closeMin
                                )
                            }

                            Divider()

                            // Günler
                            VStack(spacing: MenuLoTheme.Spacing.xs) {
                                ForEach(dayOrder, id: \.self) { day in
                                    HStack {
                                        Text(day)
                                            .font(MenuLoTheme.Fonts.body)
                                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                        Spacer()
                                        if openDays[day] == true {
                                            Text("Open @ \(String(format: "%02d:%02d", openHour, openMin)) - Close @ \(String(format: "%02d:%02d", closeHour, closeMin))")
                                                .font(MenuLoTheme.Fonts.caption)
                                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
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
                                    .padding(.vertical, 4)
                                    if day != dayOrder.last {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    // MARK: - Kaydet Butonu
                    PrimaryButton(title: "Değişiklikleri Kaydet", isLoading: isLoading) {
                        isLoading = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isLoading = false
                            showSaveAlert = true
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("My Business")
            .navigationBarTitleDisplayMode(.large)
            .alert("Kaydedildi ✅", isPresented: $showSaveAlert) {
                Button("Tamam", role: .cancel) {}
            } message: {
                Text("İşletme bilgileriniz başarıyla güncellendi.")
            }
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
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
            TextField(label, text: $text)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                .padding(MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.backgroundLight)
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
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
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
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                Picker("Dakika", selection: $minute) {
                    ForEach([0, 15, 30, 45], id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 50, height: 70)
                .clipped()
            }
            .background(MenuLoTheme.Colors.backgroundLight)
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
            HStack(spacing: MenuLoTheme.Spacing.sm) {
                Image(systemName: icon)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                Text(title)
                    .font(MenuLoTheme.Fonts.subtitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: 0) {
                content
            }
            .padding(MenuLoTheme.Spacing.lg)
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Preview
#Preview {
    MyBusinessView()
}
