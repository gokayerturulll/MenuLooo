//
//  RegisterView.swift
//  MenuLo
//
//  MenuLo/Views/Auth/RegisterView.swift
//
//  Yeni kullanıcı kayıt ekranı.
//  "Customer" ve "Business" olmak üzere iki sekmeden oluşur.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel

    // Aktif sekme: 0 = Customer, 1 = Business
    @State private var selectedTab: Int = 0

    // --- Müşteri Formu ---
    @State private var customerName     = ""
    @State private var customerEmail    = ""
    @State private var customerPassword = ""

    // --- İşletme Formu ---
    @State private var businessName     = ""
    @State private var businessEmail    = ""
    @State private var businessPassword = ""
    @State private var businessPhone    = ""
    @State private var restaurantName   = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Header
                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .frame(width: 64, height: 64)
                        .foregroundColor(MenuLoTheme.Colors.primary)

                    Text("Aramıza Katıl")
                        .font(MenuLoTheme.Fonts.largeTitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    Text("Hesap türünü seçerek devam et")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
                .padding(.top, MenuLoTheme.Spacing.xl)
                .padding(.bottom, MenuLoTheme.Spacing.lg)

                // MARK: - Custom Segmented Tab Bar
                HStack(spacing: 0) {
                    TabSegment(
                        title: "Müşteri",
                        iconName: "person.fill",
                        isSelected: selectedTab == 0
                    ) { withAnimation(.spring(response: 0.3)) { selectedTab = 0 } }

                    TabSegment(
                        title: "İşletme",
                        iconName: "building.2.fill",
                        isSelected: selectedTab == 1
                    ) { withAnimation(.spring(response: 0.3)) { selectedTab = 1 } }
                }
                .padding(4)
                .background(MenuLoTheme.Colors.divider.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large))
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.bottom, MenuLoTheme.Spacing.lg)

                // MARK: - Form Content
                if selectedTab == 0 {
                    customerForm
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    businessForm
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                }

                Spacer(minLength: MenuLoTheme.Spacing.xl)
            }
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Müşteri Formu
    private var customerForm: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {
            VStack(spacing: MenuLoTheme.Spacing.md) {
                CustomTextField(placeholder: "Ad Soyad", iconName: "person.fill", text: $customerName)
                CustomTextField(placeholder: "E-posta", iconName: "envelope.fill", text: $customerEmail)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                CustomTextField(placeholder: "Şifre", iconName: "lock.fill", text: $customerPassword, isSecure: true)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            // Hüküm & Koşullar notu
            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(MenuLoTheme.Colors.success)
                    .font(.caption)
                Text("Kaydolarak Kullanım Koşullarını kabul etmiş olursunuz.")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            PrimaryButton(title: "Hesap Oluştur", isLoading: authVM.isLoading) {
                authVM.register(
                    name: customerName,
                    email: customerEmail,
                    password: customerPassword,
                    userType: .customer
                )
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }

    // MARK: - İşletme Formu
    private var businessForm: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {
            // İşletme sahibi kişisel bilgileri
            VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.xs) {
                SectionLabel(title: "Kişisel Bilgiler", icon: "person.fill")
                VStack(spacing: MenuLoTheme.Spacing.md) {
                    CustomTextField(placeholder: "Ad Soyad", iconName: "person.fill", text: $businessName)
                    CustomTextField(placeholder: "E-posta", iconName: "envelope.fill", text: $businessEmail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    CustomTextField(placeholder: "Telefon", iconName: "phone.fill", text: $businessPhone)
                        .keyboardType(.phonePad)
                    CustomTextField(placeholder: "Şifre", iconName: "lock.fill", text: $businessPassword, isSecure: true)
                }
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            // Restoran bilgileri
            VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.xs) {
                SectionLabel(title: "Restoran Bilgileri", icon: "building.2.fill")
                CustomTextField(placeholder: "Restoran Adı", iconName: "signpost.right.fill", text: $restaurantName)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            // Pro badge bilgisi
            HStack(spacing: MenuLoTheme.Spacing.sm) {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("İşletme Hesabı Avantajları")
                        .font(MenuLoTheme.Fonts.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Text("Menü yönetimi, Yeşil Menü ve analytics paneline erişim.")
                        .font(.caption2)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
            }
            .padding()
            .background(MenuLoTheme.Colors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            PrimaryButton(title: "İşletme Hesabı Oluştur", isLoading: authVM.isLoading) {
                authVM.register(
                    name: businessName,
                    email: businessEmail,
                    password: businessPassword,
                    userType: .business
                )
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Yardımcı Bileşenler

/// Özel segmented control sekmesi
private struct TabSegment: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.footnote)
                Text(title)
                    .font(MenuLoTheme.Fonts.button)
            }
            .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MenuLoTheme.Spacing.sm)
            .background(
                isSelected
                    ? MenuLoTheme.Colors.primary
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium - 2))
        }
    }
}

/// Form bölüm başlığı
private struct SectionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundColor(MenuLoTheme.Colors.primary)
            Text(title)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthViewModel())
    }
}
