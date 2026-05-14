//
//  ReviewsView.swift
//  MenuLo
//
//  MenuLo/Views/Reviews/ReviewsView.swift
//

import SwiftUI

// MARK: - ReviewsView
struct ReviewsView: View {
    var restaurantId: Int = 0
    var menuItems: [MenuDetailItem] = []

    @StateObject private var viewModel = ReviewViewModel()
    @State private var showWriteSheet = false
    @State private var ratingFilter = 0

    private var filteredReviews: [AppReview] {
        guard ratingFilter != 0 else { return viewModel.reviews }
        return viewModel.reviews.filter {
            Int(($0.averageRating ?? 0).rounded()) == ratingFilter
        }
    }

    private var avgRating: Double {
        let ratings = viewModel.reviews.compactMap(\.averageRating)
        guard !ratings.isEmpty else { return 0 }
        return ratings.reduce(0, +) / Double(ratings.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, MenuLoTheme.Spacing.xl)
                    } else if viewModel.reviews.isEmpty {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            Text("😶").font(.system(size: 48))
                            Text("Henüz yorum yok")
                                .font(MenuLoTheme.Fonts.body)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, MenuLoTheme.Spacing.xl)
                    } else {

                        // MARK: - Rating Özeti
                        RatingSummaryCard(avg: avgRating, reviews: viewModel.reviews)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        // MARK: - Yıldız Filtresi
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MenuLoTheme.Spacing.sm) {
                                StarFilterChip(label: "Tümü", isSelected: ratingFilter == 0) {
                                    withAnimation { ratingFilter = 0 }
                                }
                                ForEach((1...5).reversed(), id: \.self) { star in
                                    StarFilterChip(
                                        label: "\(star) ⭐",
                                        isSelected: ratingFilter == star
                                    ) {
                                        withAnimation { ratingFilter = star }
                                    }
                                }
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        }

                        // MARK: - Yorum Listesi
                        if filteredReviews.isEmpty {
                            VStack(spacing: MenuLoTheme.Spacing.md) {
                                Text("😶").font(.system(size: 48))
                                Text("Bu puan için yorum bulunamadı")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            }
                            .padding(.vertical, MenuLoTheme.Spacing.xl)
                        } else {
                            VStack(spacing: MenuLoTheme.Spacing.md) {
                                ForEach(filteredReviews) { review in
                                    ReviewCard(review: review)
                                }
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        }
                    }

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.error)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    // MARK: - Yorum Yaz Butonu
                    PrimaryButton(title: "Yorum Yaz") {
                        showWriteSheet = true
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Yorumlar ve Puanlar")
            .navigationBarTitleDisplayMode(.large)
            .task {
                guard restaurantId > 0 else { return }
                await viewModel.fetchReviews(restaurantId: restaurantId)
            }
            .sheet(isPresented: $showWriteSheet) {
                WriteReviewSheet(
                    restaurantId: restaurantId,
                    menuItems: menuItems,
                    viewModel: viewModel
                )
            }
        }
    }
}

// MARK: - Rating Özet Kartı
private struct RatingSummaryCard: View {
    let avg: Double
    let reviews: [AppReview]

    private var ratingDistribution: [Int: Int] {
        var dist: [Int: Int] = [5:0, 4:0, 3:0, 2:0, 1:0]
        reviews.forEach {
            let star = Int(($0.averageRating ?? 0).rounded())
            if (1...5).contains(star) { dist[star, default: 0] += 1 }
        }
        return dist
    }

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.lg) {

            VStack(spacing: 4) {
                Text(String(format: "%.1f", avg))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                StarRow(rating: Int(avg.rounded()), size: 14)
                Text("\(reviews.count) değerlendirme")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .frame(width: 110)

            Divider()

            VStack(spacing: 4) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    HStack(spacing: 6) {
                        Text("\(star)")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .frame(width: 12)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3).fill(MenuLoTheme.Colors.divider)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(star >= 4 ? .yellow : (star == 3 ? MenuLoTheme.Colors.warning : MenuLoTheme.Colors.error))
                                    .frame(width: geo.size.width * CGFloat(ratingDistribution[star, default: 0]) / CGFloat(max(reviews.count, 1)))
                            }
                        }
                        .frame(height: 8)
                        Text("\(ratingDistribution[star, default: 0])")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .frame(width: 20)
                    }
                }
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Yorum Kartı
private struct ReviewCard: View {
    let review: AppReview
    @State private var isHelpful = false

    private var displayName: String { review.userName ?? "Kullanıcı" }

    private var avatarLetter: String {
        String(displayName.prefix(1)).uppercased()
    }

    private var relativeDate: String {
        guard let date = review.date else { return review.createdAt }
        let diff = Calendar.current.dateComponents([.day, .weekOfYear, .month], from: date, to: Date())
        if let months = diff.month, months > 0 { return "\(months) ay önce" }
        if let weeks = diff.weekOfYear, weeks > 0 { return "\(weeks) hafta önce" }
        if let days = diff.day, days > 0 { return "\(days) gün önce" }
        return "Bugün"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {

            // Kullanıcı Başlığı
            HStack {
                Text(avatarLetter)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(MenuLoTheme.Colors.primary)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(MenuLoTheme.Fonts.body)
                        .fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    HStack(spacing: 6) {
                        if let avg = review.averageRating {
                            StarRow(rating: Int(avg.rounded()), size: 12)
                        }
                        Text("·")
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        Text(relativeDate)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }

            // Detaylı puanlar (sadece verilen alanlar gösterilir)
            let detailRatings: [(String, Int)] = [
                ("Lezzet", review.taste),
                ("Servis", review.service),
                ("Ambiyans", review.attitude)
            ].compactMap { label, val in val.map { (label, $0) } }

            if !detailRatings.isEmpty {
                HStack(spacing: MenuLoTheme.Spacing.sm) {
                    ForEach(detailRatings, id: \.0) { label, val in
                        VStack(spacing: 2) {
                            Text(label)
                                .font(.caption2)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            StarRow(rating: val, size: 10)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(MenuLoTheme.Colors.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Yorum Metni
            if let content = review.content, !content.isEmpty {
                Text(content)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    .lineSpacing(4)
            }

            // Yararlı Butonu
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) { isHelpful.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(isHelpful ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.textSecondary)
                        Text("Yararlı\(isHelpful ? " (1)" : "")")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Yorum Yazma Sheet
struct WriteReviewSheet: View {
    let restaurantId: Int
    let menuItems: [MenuDetailItem]
    @ObservedObject var viewModel: ReviewViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // Detaylı Puanlama
                    detailedRatingsCard

                    // Değerlendirme metni
                    commentCard

                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.error)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    PrimaryButton(title: "Gönder", isLoading: viewModel.isSubmitting) {
                        Task {
                            let ok = await viewModel.submitDraft(restaurantId: restaurantId)
                            if ok { dismiss() }
                        }
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.md)
            }
            .background(MenuLoTheme.Colors.backgroundLight)
            .navigationTitle("Yorum Yaz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        viewModel.resetDraft()
                        dismiss()
                    }
                    .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }

    private var detailedRatingsCard: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            Text("Puanlama (İsteğe Bağlı)")
                .font(MenuLoTheme.Fonts.subtitle)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)

            detailRatingRow(label: "Lezzet",   icon: "fork.knife",       value: $viewModel.draftTaste)
            detailRatingRow(label: "Servis",    icon: "hand.raised.fill", value: $viewModel.draftService)
            detailRatingRow(label: "Ambiyans",  icon: "sparkles",         value: $viewModel.draftAttitude)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
    }

    private func detailRatingRow(label: String, icon: String, value: Binding<Int?>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(MenuLoTheme.Colors.primary)
                .frame(width: 22)
            Text(label)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Button {
                        value.wrappedValue = (value.wrappedValue == i) ? nil : i
                    } label: {
                        Image(systemName: i <= (value.wrappedValue ?? 0) ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(label) \(i) yıldız")
                }
            }
        }
    }

    private var commentCard: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
            Label("Değerlendirme (İsteğe Bağlı)", systemImage: "text.bubble.fill")
                .font(MenuLoTheme.Fonts.caption)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            ZStack(alignment: .topLeading) {
                if viewModel.draftContent.isEmpty {
                    Text("Deneyiminizi paylaşın…")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.5))
                        .padding(MenuLoTheme.Spacing.md)
                }
                TextEditor(text: $viewModel.draftContent)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    .frame(minHeight: 120)
                    .padding(MenuLoTheme.Spacing.sm)
            }
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.04), radius: 4)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }
}

// MARK: - Yardımcı Bileşenler
private struct StarRow: View {
    let rating: Int
    var size: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(.yellow)
            }
        }
    }
}

private struct StarFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(MenuLoTheme.Fonts.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textSecondary)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.vertical, 6)
                .background(isSelected ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.cardBackground)
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.pill)
                        .strokeBorder(isSelected ? Color.clear : MenuLoTheme.Colors.divider, lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
#Preview {
    ReviewsView(restaurantId: 1)
}
