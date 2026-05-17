//
//  MyBusinessView.swift
//  MenuLo
//
//  MenuLo/Views/Business/MyBusinessView.swift
//
//  İşletme sahibinin restoran profilini yönettiği ekran.
//  Veriyi MyBusinessViewModel üzerinden backend'den çeker, "Değişiklikleri Kaydet"
//  butonu ile PUT /api/restaurants/:rid'e gönderir.
//

import SwiftUI

struct MyBusinessView: View {

    @StateObject private var viewModel: MyBusinessViewModel
    @State private var restaurantStats: RestaurantStats? = nil
    @State private var statsLoading = false

    private let restaurantId: Int

    init(restaurantId: Int = 1) {
        self.restaurantId = restaurantId
        _viewModel = StateObject(wrappedValue: MyBusinessViewModel(restaurantId: restaurantId))
    }

    let dayOrder = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]

    @MainActor
    private func loadStats() async {
        statsLoading = true
        defer { statsLoading = false }
        restaurantStats = try? await NetworkManager.shared.fetchRestaurantStats(restaurantId: restaurantId)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Hero
                MyBusinessHero(
                    name: viewModel.businessName.isEmpty ? "Restoranım" : viewModel.businessName,
                    cuisine: viewModel.cuisineType.isEmpty ? "Mutfak Tipi" : viewModel.cuisineType
                )

                Spacer().frame(height: 24)

                if viewModel.isLoading && !viewModel.hasLoaded {
                    LoadingState()
                        .padding(.top, MenuLoTheme.Spacing.xxl)
                } else {
                    formContent
                }
            }
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Dükkanım")
        .navigationBarTitleDisplayMode(.large)
        .alert("Kaydedildi ✅", isPresented: $viewModel.saveSucceeded) {
            Button("Tamam", role: .cancel) { viewModel.clearSaveSuccess() }
        } message: {
            Text("İşletme bilgileriniz başarıyla güncellendi.")
        }
        .alert("Bir sorun oluştu", isPresented: $viewModel.showError) {
            Button("Tamam", role: .cancel) { viewModel.clearError() }
            Button("Tekrar Dene") {
                viewModel.clearError()
                Task { await viewModel.load(force: true) }
            }
        } message: {
            Text(viewModel.errorMessage ?? "Bilinmeyen bir hata.")
        }
        .task {
            await viewModel.load()
            await loadStats()
        }
        .refreshable {
            await viewModel.load(force: true)
            await loadStats()
        }
    }

    // MARK: - Form
    private var formContent: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {

            // İstatistikler
            if statsLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MenuLoTheme.Spacing.lg)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible()),
                              GridItem(.flexible()), GridItem(.flexible())],
                    spacing: MenuLoTheme.Spacing.sm
                ) {
                    let rating = restaurantStats.map { String(format: "%.1f", $0.avgRating) } ?? "-"
                    let reviews = restaurantStats.map { "\($0.reviewCount)" } ?? "-"
                    let price   = restaurantStats?.priceRange ?? "-"
                    StatCard(icon: "star.fill",  label: "Puan",        value: rating,  color: MenuLoTheme.Colors.warning)
                    StatCard(icon: "bubble.left.fill", label: "Yorum",  value: reviews, color: MenuLoTheme.Colors.accentPurple)
                    StatCard(icon: "turkishlirasign.circle.fill", label: "Fiyat", value: price, color: MenuLoTheme.Colors.error)
                    StatCard(icon: "leaf.fill",   label: "Yeşil Menü", value: "3",     color: MenuLoTheme.Colors.success)
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
            }

            // İşletme Bilgileri
            BusinessSection(title: "İşletme Bilgileri", icon: "info.circle.fill") {
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    EditableField(label: "Restoran Adı", icon: "building.2", text: $viewModel.businessName)
                    EditableField(label: "Mutfak Tipi",  icon: "fork.knife", text: $viewModel.cuisineType)
                    EditableField(label: "Adres",        icon: "mappin",     text: $viewModel.address)
                    EditableField(label: "Telefon",      icon: "phone",      text: $viewModel.phone)
                    EditableField(label: "Web Sitesi",   icon: "globe",      text: $viewModel.website)

                    VStack(alignment: .leading, spacing: 6) {
                        Label("Açıklama", systemImage: "text.alignleft")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $viewModel.description)
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

            // Konum
            BusinessSection(title: "Harita Konumu", icon: "map.fill") {
                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        CoordinateField(label: "Enlem",  value: $viewModel.latitude)
                        CoordinateField(label: "Boylam", value: $viewModel.longitude)
                    }

                    Label("Müşteriler bu koordinatta haritada görür.",
                          systemImage: "info.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 4)
                }
            }

            // Çalışma Saatleri
            BusinessSection(title: "Çalışma Saatleri", icon: "clock.fill") {
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    HStack(spacing: MenuLoTheme.Spacing.md) {
                        TimePickerCard(
                            label: "Açılış",
                            icon: "sunrise.fill",
                            color: MenuLoTheme.Colors.success,
                            hour: $viewModel.workingHours.openHour,
                            minute: $viewModel.workingHours.openMinute
                        )
                        Image(systemName: "arrow.right")
                            .foregroundColor(.secondary)
                        TimePickerCard(
                            label: "Kapanış",
                            icon: "sunset.fill",
                            color: MenuLoTheme.Colors.error,
                            hour: $viewModel.workingHours.closeHour,
                            minute: $viewModel.workingHours.closeMinute
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
                                if viewModel.workingHours.openDays[day] == true {
                                    Text(String(format: "%02d:%02d – %02d:%02d",
                                                viewModel.workingHours.openHour,
                                                viewModel.workingHours.openMinute,
                                                viewModel.workingHours.closeHour,
                                                viewModel.workingHours.closeMinute))
                                        .font(MenuLoTheme.Fonts.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Kapalı")
                                        .font(MenuLoTheme.Fonts.caption)
                                        .foregroundColor(MenuLoTheme.Colors.error)
                                }
                                Toggle("", isOn: Binding(
                                    get: { viewModel.workingHours.openDays[day] ?? false },
                                    set: { viewModel.workingHours.openDays[day] = $0 }
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

            // Kaydet
            PrimaryButton(title: "Değişiklikleri Kaydet", isLoading: viewModel.isSubmitting) {
                Task { await viewModel.save() }
            }
            .disabled(viewModel.isSubmitting)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .padding(.bottom, MenuLoTheme.Spacing.xxl)
        }
        .padding(.top, MenuLoTheme.Spacing.lg)
    }
}

// MARK: - Loading
private struct LoadingState: View {
    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MenuLoTheme.Colors.primary))
                .scaleEffect(1.4)
            Text("Dükkan bilgileri yükleniyor…")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Hero
private struct MyBusinessHero: View {
    let name: String
    let cuisine: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            MenuLoTheme.Colors.primary.opacity(0.85),
                            MenuLoTheme.Colors.accentOrange.opacity(0.95)
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
                    Text("🍽️").font(.system(size: 38))
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

// MARK: - Coordinate Field
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

// MARK: - Stat Card
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

// MARK: - Editable Field
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

// MARK: - Time Picker Card
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

// MARK: - Section
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

            VStack(spacing: 0) { content }
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
        MyBusinessView(restaurantId: 1)
    }
}
