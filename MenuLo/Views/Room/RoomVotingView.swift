import SwiftUI
import UIKit

// MARK: - RoomVotingView
// Oda içi oylama ekranı. Gerçek restoranlar backend'den çekilir;
// kullanıcı oy verdikten sonra ilgili kartın butonları devre dışı kalır.

struct RoomVotingView: View {

    let room: Room
    let onLeave: () -> Void

    @EnvironmentObject private var viewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss

    /// match_found gelince 2s banner gösterilir, ardından bu flag navigation'ı tetikler.
    @State private var navigateToMatch = false
    @State private var selectedRestaurant: Restaurant?

    var body: some View {
        ZStack(alignment: .top) {
            MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

            VStack(spacing: 0) {
                roomHeader
                    .background(MenuLoTheme.Colors.cardBackground)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                contentArea
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Ayrıl") {
                    onLeave()
                }
                .foregroundColor(.red)
            }
        }
        .animation(.spring(response: 0.35), value: viewModel.matchedRestaurantId)
        .animation(.spring(response: 0.35), value: viewModel.isDeckExhausted)
        .task { await viewModel.fetchRoomRestaurants() }
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetailView(restaurant: restaurant)
        }
        // match_found socket event'i gelince: 2s banner, sonra RestaurantDetailView'a yönlendir.
        .onChange(of: viewModel.matchedRestaurantId) { newId in
            guard newId != nil else { return }
            Task {
                try? await Task.sleep(for: .seconds(2))
                navigateToMatch = true
            }
        }
        .navigationDestination(isPresented: $navigateToMatch) {
            matchedRestaurantDestination
        }
    }

    // MARK: - Match Destination

    /// NavigationStack'in gideceği RestaurantDetailView + aksiyonlar.
    @ViewBuilder
    private var matchedRestaurantDestination: some View {
        if let matchId    = viewModel.matchedRestaurantId,
           let matchIdInt = Int(matchId),
           let matched    = viewModel.roomRestaurants.first(where: { $0.restaurantId == matchIdInt }) {
            RestaurantDetailView(restaurant: matched.asRestaurant)
                .safeAreaInset(edge: .bottom) {
                    MatchActionBar(restaurant: matched)
                }
        }
    }

    // MARK: - İçerik Alanı

    @ViewBuilder
    private var contentArea: some View {
        if viewModel.roomRestaurants.isEmpty {
            loadingOrEmptyView
        } else {
            restaurantList
        }
    }

    private var loadingOrEmptyView: some View {
        VStack(spacing: MenuLoTheme.Spacing.lg) {
            Spacer()
            if viewModel.isDeckExhausted {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.system(size: 48))
                    .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.7))
                Text("Grupça karara varılamadı")
                    .font(MenuLoTheme.Fonts.subtitle).fontWeight(.semibold)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Text("Yeni restoranlar aranıyor...")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(MenuLoTheme.Colors.primary)
            } else if viewModel.isLoading || viewModel.errorMessage == nil {
                ProgressView()
                    .scaleEffect(1.4)
                    .tint(MenuLoTheme.Colors.primary)
                Text("Restoranlar yükleniyor...")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 44))
                    .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.5))
                Text(viewModel.errorMessage ?? "Bir hata oluştu.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Tekrar Dene") {
                    Task { await viewModel.fetchRoomRestaurants() }
                }
                .font(MenuLoTheme.Fonts.button)
                .foregroundColor(.white)
                .padding(.horizontal, MenuLoTheme.Spacing.xl)
                .padding(.vertical, MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.primary)
                .cornerRadius(MenuLoTheme.CornerRadius.large)
            }
            Spacer()
        }
        .padding(MenuLoTheme.Spacing.lg)
    }

    private var restaurantList: some View {
        ScrollView {
            VStack(spacing: MenuLoTheme.Spacing.md) {

                // Deste tükenme banner'ı (deck_exhausted eventi geldiğinde görünür)
                if viewModel.isDeckExhausted {
                    deckExhaustedBanner
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Eşleşme banner'ı (match_found eventi geldiğinde görünür)
                if let matchId = viewModel.matchedRestaurantId,
                   let matchIdInt = Int(matchId),
                   let matched = viewModel.roomRestaurants.first(where: { $0.restaurantId == matchIdInt }) {
                    matchBanner(matched)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ForEach(viewModel.roomRestaurants) { restaurant in
                    let rid = String(restaurant.restaurantId)
                    VotingCard(
                        restaurant:        restaurant,
                        vote:              viewModel.votes[rid],
                        totalParticipants: max(viewModel.participantIds.count, 1),
                        isVoted:           viewModel.votedRestaurantIds.contains(rid),
                        onApprove: {
                            viewModel.submitVote(restaurantId: rid, isApproved: true)
                        },
                        onReject: {
                            viewModel.submitVote(restaurantId: rid, isApproved: false)
                        },
                        onViewDetail: {
                            selectedRestaurant = restaurant.asRestaurant
                        }
                    )
                }
            }
            .padding(MenuLoTheme.Spacing.lg)
            .padding(.bottom, MenuLoTheme.Spacing.xl)
        }
    }

    // MARK: - Oda Başlığı

    private var roomHeader: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {

            HStack(spacing: 4) {
                Text("PIN")
                    .font(.caption2).fontWeight(.semibold)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                Text(room.pinCode)
                    .font(.system(.caption, design: .monospaced)).fontWeight(.bold)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .tracking(3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MenuLoTheme.Colors.primary.opacity(0.08))
            .cornerRadius(MenuLoTheme.CornerRadius.medium)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isSocketConnected ? MenuLoTheme.Colors.success : .gray)
                    .frame(width: 8, height: 8)
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                Text("\(max(viewModel.participantIds.count, 1))")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
        .padding(.vertical, MenuLoTheme.Spacing.md)
    }

    // MARK: - Deste Tükenme Banner'ı

    private var deckExhaustedBanner: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 2) {
                Text("Grupça karara varılamadı")
                    .font(MenuLoTheme.Fonts.subtitle).fontWeight(.bold)
                    .foregroundColor(.white)
                Text("Yeni restoranlar aranıyor...")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            ProgressView()
                .tint(.white)
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(
            LinearGradient(
                colors: [MenuLoTheme.Colors.accentIndigo, MenuLoTheme.Colors.accentIndigoLight],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: MenuLoTheme.Colors.accentIndigo.opacity(0.4), radius: 12, x: 0, y: 4)
    }

    // MARK: - Eşleşme Banner'ı

    @ViewBuilder
    private func matchBanner(_ restaurant: RoomRestaurant) -> some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {
            Text(restaurant.categoryEmoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text("Eşleşme Bulundu!")
                    .font(MenuLoTheme.Fonts.subtitle).fontWeight(.bold)
                    .foregroundColor(.white)
                Text(restaurant.name)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
        .padding(MenuLoTheme.Spacing.md)
        .background(
            LinearGradient(
                colors: [MenuLoTheme.Colors.primary, MenuLoTheme.Colors.accentOrange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 12, x: 0, y: 4)
    }
}

// MARK: - VotingCard

private struct VotingCard: View {

    let restaurant:        RoomRestaurant
    let vote:              RestaurantVote?
    let totalParticipants: Int
    let isVoted:           Bool
    let onApprove:         () -> Void
    let onReject:          () -> Void
    let onViewDetail:      () -> Void

    private var approvedCount: Int { vote?.approvedBy.count ?? 0 }
    private var rejectedCount: Int { vote?.rejectedBy.count ?? 0 }
    private var approvalRatio: CGFloat {
        totalParticipants > 0 ? CGFloat(approvedCount) / CGFloat(totalParticipants) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {

            // Restoran görseli + bilgisi (tıklanınca detay açılır)
            Button(action: onViewDetail) {
                HStack(spacing: MenuLoTheme.Spacing.md) {
                    restaurantThumbnail
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(restaurant.name)
                            .font(MenuLoTheme.Fonts.body).fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Text(restaurant.cuisineDisplay)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        if let addr = restaurant.address {
                            Text(addr)
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    if isVoted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
            }
            .buttonStyle(.plain)

            // Oy sayaçları
            HStack {
                Label("\(approvedCount)/\(totalParticipants) Onay", systemImage: "hand.thumbsup.fill")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(.green)
                Spacer()
                Label("\(rejectedCount) Red", systemImage: "hand.thumbsdown.fill")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(.red)
            }

            // Onay ilerleme çubuğu
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red.opacity(0.15))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.green],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * approvalRatio, height: 6)
                        .animation(.spring(response: 0.4), value: approvalRatio)
                }
            }
            .frame(height: 6)

            // Aksiyon butonları — oy verildikten sonra disabled
            HStack(spacing: MenuLoTheme.Spacing.md) {
                Button(action: onApprove) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Onayla")
                    }
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .background(isVoted ? Color.green.opacity(0.35) : Color.green)
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                    .shadow(color: isVoted ? .clear : Color.green.opacity(0.35), radius: 6)
                }
                .disabled(isVoted)

                Button(action: onReject) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("Reddet")
                    }
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .background(isVoted ? Color.red.opacity(0.35) : Color.red)
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                    .shadow(color: isVoted ? .clear : Color.red.opacity(0.3), radius: 6)
                }
                .disabled(isVoted)
            }

            if isVoted {
                Text("Oyunuz kaydedildi.")
                    .font(.caption2)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .opacity(isVoted ? 0.75 : 1)
        .animation(.easeInOut(duration: 0.25), value: isVoted)
    }

    // Görsel URL yoksa emoji tabanlı placeholder göster
    @ViewBuilder
    private var restaurantThumbnail: some View {
        ZStack {
            MenuLoTheme.Colors.primary.opacity(0.08)
            Text(restaurant.categoryEmoji)
                .font(.system(size: 30))
        }
    }
}

// MARK: - MatchActionBar
// Eşleşme sonuç ekranının altında sabit duran "Ara" ve "Rezervasyon Yap" butonu.

private struct MatchActionBar: View {

    let restaurant: RoomRestaurant

    private var phoneURL: URL? {
        guard let phone = restaurant.phone, !phone.isEmpty else { return nil }
        let digits = phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel://\(digits)")
    }

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.md) {

            // Ara — numara yoksa disabled
            Button {
                guard let url = phoneURL else { return }
                UIApplication.shared.open(url)
            } label: {
                Label("Ara", systemImage: "phone.fill")
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(phoneURL != nil ? .white : MenuLoTheme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .background(
                        phoneURL != nil
                            ? MenuLoTheme.Colors.success
                            : MenuLoTheme.Colors.cardBackground
                    )
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
            }
            .disabled(phoneURL == nil)

            // Rezervasyon Yap — website varsa Safari, yoksa Apple Maps
            Button {
                if let website = restaurant.website,
                   !website.isEmpty,
                   let url = URL(string: website) {
                    UIApplication.shared.open(url)
                } else if let url = URL(string:
                    "http://maps.apple.com/?daddr=\(restaurant.latitude),\(restaurant.longitude)"
                ) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Rezervasyon Yap", systemImage: "calendar.badge.plus")
                    .font(MenuLoTheme.Fonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MenuLoTheme.Spacing.md)
                    .background(MenuLoTheme.Colors.primary)
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: -2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoomVotingView(
            room: Room(roomId: 1, pinCode: "AB1CD2", hostId: 1, name: "Cuma Akşamı",
                       categories: ["Pizza"], status: "active", createdAt: ""),
            onLeave: {}
        )
        .environmentObject(RoomViewModel())
    }
}
