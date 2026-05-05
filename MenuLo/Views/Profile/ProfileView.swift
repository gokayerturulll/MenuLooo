//
//  ProfileView.swift
//  MenuLo
//
//  Profil ve Ayarlar sekmesi.
//  Müşteri için: favoriler, değerlendirmeler, ayarlar.
//  İşletme sahibi için: Menu Manager, My Business, Reviews bağlantıları.
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Profil Hero
                    ProfileHeroSection(authViewModel: authViewModel)

                    // MARK: - İşletme Sahibi Paneli
                    if authViewModel.currentUser?.userType == .business {
                        BusinessPanelSection()
                    }

                    // MARK: - Genel Menü
                    ProfileMenuSection(authViewModel: authViewModel)
                }
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Profil Hero
private struct ProfileHeroSection: View {
    let authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    )
                    .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 10)

                Circle()
                    .fill(MenuLoTheme.Colors.success)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    )
            }

            VStack(spacing: 4) {
                Text(authViewModel.currentUser?.name ?? "Kullanıcı")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                Text(authViewModel.currentUser?.email ?? "")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)

                // Rozet
                Text(authViewModel.currentUser?.userType.displayName ?? "Müşteri")
                    .font(MenuLoTheme.Fonts.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .padding(.vertical, MenuLoTheme.Spacing.xs)
                    .background(
                        authViewModel.currentUser?.userType == .business
                            ? Color(hex: "#6C5CE7")
                            : MenuLoTheme.Colors.primary
                    )
                    .cornerRadius(MenuLoTheme.CornerRadius.pill)
            }

            // İstatistik Satırı
            HStack(spacing: 0) {
                StatItem(value: "28", label: "Ziyaret")
                Divider().frame(height: 32)
                StatItem(value: "14", label: "Favori")
                Divider().frame(height: 32)
                StatItem(value: "4.8 ⭐", label: "Puanım")
            }
            .padding(.vertical, MenuLoTheme.Spacing.md)
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 6)
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
    }
}

// MARK: - İşletme Paneli
private struct BusinessPanelSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            SectionTitle(title: "İşletme Yönetimi", icon: "building.2.fill")
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.lg)

            VStack(spacing: 1) {
                NavigationLink(destination: MenuManagerView()) {
                    ProfileRow(
                        icon: "list.bullet.rectangle.fill",
                        iconColor: MenuLoTheme.Colors.primary,
                        title: "Menu Manager",
                        subtitle: "Ürün ekle, düzenle ve yönet"
                    )
                }

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                NavigationLink(destination: MyBusinessView()) {
                    ProfileRow(
                        icon: "building.2.fill",
                        iconColor: Color(hex: "#6C5CE7"),
                        title: "My Business",
                        subtitle: "İşletme bilgileri ve çalışma saatleri"
                    )
                }

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                NavigationLink(destination: ReviewsView()) {
                    ProfileRow(
                        icon: "star.bubble.fill",
                        iconColor: .yellow,
                        title: "Değerlendirmeler",
                        subtitle: "Müşteri yorumlarını gör ve yanıtla"
                    )
                }
            }
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 6)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Genel Menü Bölümü
private struct ProfileMenuSection: View {
    let authViewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            SectionTitle(title: "Hesabım", icon: "person.fill")
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.lg)

            VStack(spacing: 1) {
                NavigationLink(destination: FavouritesView()) {
                    ProfileRow(icon: "heart.fill", iconColor: .red, title: "Favorilerim", subtitle: "Beğenilen restoranlar ve ürünler")
                }

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                NavigationLink(destination: ReviewsView()) {
                    ProfileRow(icon: "star.fill", iconColor: .yellow, title: "Yorumlarım", subtitle: "Yaptığın değerlendirmeler")
                }

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                ProfileRow(icon: "faceid", iconColor: MenuLoTheme.Colors.success, title: "Face ID / Touch ID", subtitle: "Biyometrik giriş")

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                ProfileRow(icon: "bell.fill", iconColor: MenuLoTheme.Colors.warning, title: "Bildirimler", subtitle: "Yeşil Menü ve fırsat uyarıları")

                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)

                ProfileRow(icon: "gearshape.fill", iconColor: MenuLoTheme.Colors.textSecondary, title: "Ayarlar", subtitle: "Dil, gizlilik, hesap")
            }
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 6)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            // Çıkış Butonu
            Button {
                authViewModel.logout()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Çıkış Yap")
                        .font(MenuLoTheme.Fonts.button)
                }
                .foregroundColor(MenuLoTheme.Colors.error)
                .frame(maxWidth: .infinity)
                .padding(MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.error.opacity(0.1))
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .overlay(
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                        .strokeBorder(MenuLoTheme.Colors.error.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .padding(.bottom, MenuLoTheme.Spacing.xl)
        }
    }
}

// MARK: - Yardımcı Bileşenler
private struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(MenuLoTheme.Fonts.subtitle)
                .fontWeight(.bold)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.5))
        }
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
        .padding(.vertical, MenuLoTheme.Spacing.md)
    }
}

private struct SectionTitle: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(MenuLoTheme.Colors.primary)
                .font(.footnote)
            Text(title)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(.semibold)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

// MARK: - Preview
#Preview("Müşteri") {
    ProfileView()
        .environmentObject(AuthViewModel())
}

#Preview("İşletme") {
    let vm = AuthViewModel()
    vm.currentUser = User.businessExample
    return ProfileView()
        .environmentObject(vm)
}
