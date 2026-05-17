//
//  BusinessAccountView.swift
//  MenuLo
//
//  MenuLo/Views/Business/BusinessAccountView.swift
//
//  İşletme sahibinin hesap sekmesi: avatar, kullanıcı bilgileri, hesap ayarları
//  ve çıkış. Tasarım dili ProfileView ile birebir uyumlu.
//

import SwiftUI

struct BusinessAccountView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showLogoutConfirm = false

    private var avatarInitials: String {
        let name = authVM.currentUser?.name ?? "?"
        return String(name.prefix(1)).uppercased()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Hero
                AccountHero(
                    initials: avatarInitials,
                    name: authVM.currentUser?.name ?? "İşletme Sahibi",
                    email: authVM.currentUser?.email ?? "isletme@menulo.com"
                )

                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // İşletme bağlantıları
                    AccountMenuGroup(title: "İşletme", icon: "building.2.fill") {
                        NavigationLink(destination: MyBusinessView(restaurantId: authVM.currentUser?.restaurantId ?? 1)) {
                            AccountRow(
                                icon: "storefront.fill",
                                iconColor: MenuLoTheme.Colors.primary,
                                title: "Dükkan Bilgileri",
                                subtitle: "Restoran adı, adres, çalışma saatleri"
                            )
                        }
                        Divider().padding(.leading, 70)

                        NavigationLink(destination: MenuManagerView(restaurantId: authVM.currentUser?.restaurantId ?? 1)) {
                            AccountRow(
                                icon: "list.bullet.rectangle.fill",
                                iconColor: MenuLoTheme.Colors.success,
                                title: "Menü Yönetimi",
                                subtitle: "Ürünleri ekle, düzenle, sil"
                            )
                        }
                        Divider().padding(.leading, 70)

                        NavigationLink(destination: ReviewsView()) {
                            AccountRow(
                                icon: "star.bubble.fill",
                                iconColor: .yellow,
                                title: "Değerlendirmeler",
                                subtitle: "Müşteri yorumlarını gör ve yanıtla"
                            )
                        }
                    }

                    // Hesap ayarları
                    AccountMenuGroup(title: "Hesap Ayarları", icon: "gearshape.fill") {
                        AccountRow(
                            icon: "person.crop.circle.fill",
                            iconColor: MenuLoTheme.Colors.primary,
                            title: "Profil Bilgileri",
                            subtitle: "Ad, e-posta, iletişim"
                        )
                        Divider().padding(.leading, 70)
                        AccountRow(
                            icon: "bell.badge.fill",
                            iconColor: MenuLoTheme.Colors.warning,
                            title: "Bildirimler",
                            subtitle: "Sipariş ve yorum uyarıları"
                        )
                        Divider().padding(.leading, 70)
                        AccountRow(
                            icon: "lock.shield.fill",
                            iconColor: MenuLoTheme.Colors.error,
                            title: "Gizlilik ve Güvenlik",
                            subtitle: "Şifre, oturum yönetimi"
                        )
                    }

                    // Çıkış Yap
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Çıkış Yap")
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
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xxl)
                }
                .padding(.top, MenuLoTheme.Spacing.lg)
            }
        }
        .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
        .navigationTitle("Hesap")
        .navigationBarTitleDisplayMode(.large)
        .alert("Çıkış Yap", isPresented: $showLogoutConfirm) {
            Button("İptal", role: .cancel) {}
            Button("Çıkış Yap", role: .destructive) {
                authVM.logout()
            }
        } message: {
            Text("Hesabından çıkmak istediğine emin misin?")
        }
    }
}

// MARK: - Hero
private struct AccountHero: View {
    let initials: String
    let name: String
    let email: String

    var body: some View {
        VStack(alignment: .center, spacing: MenuLoTheme.Spacing.lg) {

            HStack {
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 104, height: 104)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.primary.opacity(0.85), MenuLoTheme.Colors.accentOrange.opacity(0.85)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 94, height: 94)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )
                        .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 12)

                    Circle()
                        .fill(MenuLoTheme.Colors.accentPurple)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        )
                        .offset(x: 2, y: 2)
                }
                .frame(width: 110, height: 110)
                Spacer()
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .center, spacing: 4) {
                Text(name)
                    .font(MenuLoTheme.Fonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(email)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(.secondary)

                Text("İşletme")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .cornerRadius(MenuLoTheme.CornerRadius.pill)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(MenuLoTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(MenuLoTheme.Colors.cardBackground)
    }
}

// MARK: - Menu Group
private struct AccountMenuGroup<Content: View>: View {
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
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .primary.opacity(0.05), radius: 6)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

private struct AccountRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 17))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        BusinessAccountView()
            .environmentObject({
                let vm = AuthViewModel()
                vm.currentUser = User.businessExample
                vm.isAuthenticated = true
                return vm
            }())
    }
}
