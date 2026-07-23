//
//  ProfileView.swift
//  MenuLo
//
//  Profil ve Ayarlar sekmesi.
//  Dairesel avatar · İsim/Mail · Geçmiş Siparişler · Hesap Ayarları · İşletme Hesabına Geç
//

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var statsViewModel = UserStatsViewModel()
    @State private var showBusinessSwitch = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: - Custom Header
                HStack {
                    Text("Profil")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.xs)
                .padding(.bottom, MenuLoTheme.Spacing.sm)

                // MARK: - Hero Section
                ProfileHeroSection(authViewModel: authViewModel, statsViewModel: statsViewModel)

                    // MARK: - İşletme Paneli (sadece business user için)
                    if authViewModel.currentUser?.userType == .business {
                        BusinessPanelSection()
                    }

                    // MARK: - Menü Bölümleri
                    VStack(spacing: MenuLoTheme.Spacing.lg) {

                        // Geçmiş Siparişler
                        ProfileMenuGroup(title: "Aktivitelerim", icon: "clock.fill") {
                            NavigationLink(destination: PlaceholderView(title: "Geçmiş Siparişlerim")) {
                                ProfileRow(icon: "bag.fill",           iconColor: MenuLoTheme.Colors.primary,       title: "Geçmiş Siparişlerim",   subtitle: "Tüm sipariş geçmişini gör")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: FavouritesView()) {
                                ProfileRow(icon: "heart.fill",        iconColor: .red,                             title: "Favorilerim",            subtitle: "Beğendiğin restoranlar ve ürünler")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: ReviewsView(restaurantId: 0)) {
                                ProfileRow(icon: "star.fill",          iconColor: .yellow,                          title: "Yorumlarım",             subtitle: "Yazdığın değerlendirmeler")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: PlaceholderView(title: "Rozetlerim")) {
                                ProfileRow(icon: "trophy.fill",        iconColor: MenuLoTheme.Colors.warning,            title: "Rozetlerim",             subtitle: "Kazandığın ödül rozetleri")
                            }
                        }

                        // Hesap Ayarları
                        ProfileMenuGroup(title: "Hesap Ayarları", icon: "gearshape.fill") {
                            NavigationLink(destination: PlaceholderView(title: "Profil Bilgilerini Düzenle")) {
                                ProfileRow(icon: "person.crop.circle.fill", iconColor: MenuLoTheme.Colors.primary, title: "Profil Bilgilerini Düzenle", subtitle: "Ad, fotoğraf, iletişim")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: PlaceholderView(title: "Face ID / Touch ID")) {
                                ProfileRow(icon: "faceid",              iconColor: MenuLoTheme.Colors.success,       title: "Face ID / Touch ID",     subtitle: "Biyometrik güvenli giriş")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: PlaceholderView(title: "Bildirimler")) {
                                ProfileRow(icon: "bell.badge.fill",     iconColor: MenuLoTheme.Colors.warning,       title: "Bildirimler",            subtitle: "Yeşil Menü ve fırsat uyarıları")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: PlaceholderView(title: "Dil ve Bölge")) {
                                ProfileRow(icon: "globe",               iconColor: MenuLoTheme.Colors.accentPurple,            title: "Dil ve Bölge",           subtitle: "Türkçe · Türkiye")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: ChangePasswordView()) {
                                ProfileRow(icon: "key.fill",        iconColor: MenuLoTheme.Colors.primary,       title: "Şifreyi Değiştir",      subtitle: "Mevcut şifreni güncelle")
                            }
                            Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                            NavigationLink(destination: PlaceholderView(title: "Gizlilik ve Güvenlik")) {
                                ProfileRow(icon: "lock.shield.fill",    iconColor: MenuLoTheme.Colors.error,         title: "Gizlilik ve Güvenlik",   subtitle: "Veri ve hesap koruması")
                            }
                        }

                        // İşletme Hesabına Geç
                        Button {
                            showBusinessSwitch = true
                        } label: {
                            HStack(spacing: MenuLoTheme.Spacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(
                                            LinearGradient(
                                                colors: [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("İşletme Hesabına Geç")
                                        .font(MenuLoTheme.Fonts.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                                    Text("Kendi restoranını ekle ve yönet")
                                        .font(MenuLoTheme.Fonts.caption)
                                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.5))
                            }
                            .padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.cardBackground)
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                    .strokeBorder(MenuLoTheme.Colors.accentPurple.opacity(0.3), lineWidth: 1.5)
                            )
                            .shadow(color: MenuLoTheme.Colors.accentPurple.opacity(0.15), radius: 8, x: 0, y: 3)
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        // Çıkış Yap
                        Button { authViewModel.logout() } label: {
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
                        .padding(.bottom, 90)
                    }
                    .padding(.top, MenuLoTheme.Spacing.lg)
                }
            }
        .background(MenuLoTheme.Colors.backgroundLight)
        .navigationBarHidden(true)
        .sheet(isPresented: $showBusinessSwitch) {
            BusinessSwitchSheet()
        }
        .task { await statsViewModel.fetchStats() }
    }
}

// MARK: - Profil Hero
private struct ProfileHeroSection: View {
    let authViewModel: AuthViewModel
    let statsViewModel: UserStatsViewModel

    var body: some View {
        VStack(alignment: .center, spacing: MenuLoTheme.Spacing.lg) {

            // Avatar + Kamera Rozeti — HStack + Spacer ile yatayda kesin ortala
            // (kamera ikonunun offset'i ZStack genişliğini etkilediğinden
            //  düz VStack alignment'ı görsel merkezi kaçırıyordu).
            
                
                // Avatar + Kamera Rozeti
            ZStack {
                // Gradient Ring
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

                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [MenuLoTheme.Colors.primary.opacity(0.8), MenuLoTheme.Colors.accentOrange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 94, height: 94)
                    .overlay(
                        Text(avatarInitials)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 12)
            }
            // Kamera ikonunu ana çemberin yapısını bozmadan dışarıdan ekliyoruz
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(MenuLoTheme.Colors.success)
                    .frame(width: 28, height: 28) // Kamera rozetini bir tık büyüttüm, daha şık durur
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    )
                    .offset(x: 4, y: 4) // Rozeti çemberin hafif dışına taşırır
            }
            .frame(maxWidth: .infinity, alignment: .center) // Ekrana jilet gibi ortalar
                
            
            

            // İsim / Mail — yatayda kesin ortala
            VStack(alignment: .center, spacing: 4) {
                Text(authViewModel.currentUser?.name ?? "Kullanıcı Adı")
                    .font(MenuLoTheme.Fonts.title)
                    .fontWeight(.bold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(authViewModel.currentUser?.email ?? "kullanici@menulo.com")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                // Tip rozeti
                Text(authViewModel.currentUser?.userType.displayName ?? "Müşteri")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, MenuLoTheme.Spacing.md)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: authViewModel.currentUser?.userType == .business
                                ? [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight]
                                : [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(MenuLoTheme.CornerRadius.pill)
            }
            .frame(maxWidth: .infinity)

            // İstatistik Satırı
            HStack(spacing: 0) {
                if statsViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MenuLoTheme.Spacing.md)
                } else {
                    ProfileStatItem(value: statsViewModel.visitCountText,    label: "Ziyaret",    icon: "fork.knife")
                    Divider().frame(height: 32)
                    ProfileStatItem(value: statsViewModel.favouriteCountText, label: "Favori",     icon: "heart.fill")
                    Divider().frame(height: 32)
                    ProfileStatItem(value: statsViewModel.avgRatingText,      label: "Avg Rating", icon: "star.fill")
                }
            }
            .padding(.vertical, MenuLoTheme.Spacing.md)
            .background(MenuLoTheme.Colors.backgroundLight)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .strokeBorder(MenuLoTheme.Colors.divider, lineWidth: 1)
            )
        }
        .padding(MenuLoTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(MenuLoTheme.Colors.cardBackground)
    }

    private var avatarInitials: String {
        let name = authViewModel.currentUser?.name ?? "?"
        return String(name.prefix(1)).uppercased()
    }
}

// MARK: - İşletme Paneli
private struct BusinessPanelSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "building.2.fill")
                    .foregroundColor(MenuLoTheme.Colors.accentPurple)
                    .font(.footnote)
                Text("İşletme Yönetimi")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .padding(.top, MenuLoTheme.Spacing.lg)

            VStack(spacing: 1) {
                NavigationLink(destination: MenuManagerView(restaurantId: 1)) {
                    ProfileRow(icon: "list.bullet.rectangle.fill", iconColor: MenuLoTheme.Colors.primary,    title: "Menu Manager",  subtitle: "Ürün ekle, düzenle ve yönet")
                }
                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                NavigationLink(destination: MyBusinessView(restaurantId: 1)) {
                    ProfileRow(icon: "building.2.fill",            iconColor: MenuLoTheme.Colors.accentPurple,         title: "My Business",   subtitle: "İşletme bilgileri ve çalışma saatleri")
                }
                Divider().padding(.horizontal, MenuLoTheme.Spacing.lg)
                NavigationLink(destination: ReviewsView(restaurantId: 0)) {
                    ProfileRow(icon: "star.bubble.fill",           iconColor: .yellow,                        title: "Değerlendirmeler", subtitle: "Müşteri yorumlarını gör ve yanıtla")
                }
            }
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 6)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - İşletme Geçiş Sheet
private struct BusinessSwitchSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: MenuLoTheme.Spacing.xl) {

                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [MenuLoTheme.Colors.accentPurple, MenuLoTheme.Colors.accentPurpleLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .shadow(color: MenuLoTheme.Colors.accentPurple.opacity(0.4), radius: 16)

                VStack(spacing: MenuLoTheme.Spacing.sm) {
                    Text("İşletme Hesabı Oluştur")
                        .font(MenuLoTheme.Fonts.largeTitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)

                    Text("Restoranını Menulo'ya ekle,\nmenünü yönet ve müşterilerinle buluş.")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: MenuLoTheme.Spacing.md) {
                    PrimaryButton(title: "Başla — İşletme Oluştur") { dismiss() }
                    Button("Şimdi Değil") { dismiss() }
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                Spacer()
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
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

// MARK: - Yardımcı Bileşenler
private struct ProfileStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileMenuGroup<Content: View>: View {
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
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            VStack(spacing: 0) {
                content
            }
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 6)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
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
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 17))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
        .padding(.vertical, 12)
    }
}

// MARK: - Placeholder View
struct PlaceholderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(MenuLoTheme.Colors.primary)
            
            Text("\(title) Çok Yakında!")
                .font(MenuLoTheme.Fonts.title)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Bu özellik üzerinde çalışıyoruz. Lütfen daha sonra tekrar deneyin.")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MenuLoTheme.Spacing.xl)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews
#Preview("Müşteri") {
    ProfileView()
        .environmentObject(AuthViewModel())
}

#Preview("İşletme") {
    ProfileView()
        .environmentObject({
            let vm = AuthViewModel()
            vm.currentUser = User.businessExample
            return vm
        }())
}
