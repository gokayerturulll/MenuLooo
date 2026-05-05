//
//  ReviewsView.swift
//  MenuLo
//
//  MenuLo/Views/Reviews/ReviewsView.swift
//
//  Kullanıcıların yemek ve restoran değerlendirmeleri yaptığı,
//  işletme sahiplerinin yanıt dönebileceği Review & Rating ekranı.
//

import SwiftUI

// MARK: - Mock Models
fileprivate struct Review: Identifiable {
    let id = UUID()
    let userName: String
    let userAvatar: String
    let rating: Int       // 1-5
    let date: String
    let comment: String
    let ownerReply: String?
    let isVerified: Bool
    let itemName: String?  // nil ise restoran yorumu
    let helpfulCount: Int
}

// MARK: - ReviewsView
struct ReviewsView: View {

    @State private var selectedSegment = 0  // 0 = Meal, 1 = Restaurant
    @State private var showWriteSheet  = false
    @State private var ratingFilter    = 0  // 0 = Tümü

    fileprivate let mealReviews: [Review] = [
        Review(userName: "Elif K.", userAvatar: "🧑‍🦰", rating: 5, date: "2 gün önce",
               comment: "Margherita pizzanın hamuru inanılmazdı! Çıtır çıtır dışı, yumuşak içiyle mükemmeldi. Kesinlikle tekrar sipariş vereceğim.",
               ownerReply: "Teşekkürler Elif Hanım! Sizi yeniden bekliyoruz 🍕",
               isVerified: true, itemName: "Margherita Pizza", helpfulCount: 12),

        Review(userName: "Mert A.", userAvatar: "👨", rating: 4, date: "5 gün önce",
               comment: "Wagyu burger güzeldi ama biraz fazla pişmişti. Servis hızlıydı.",
               ownerReply: nil, isVerified: true, itemName: "Wagyu Burger", helpfulCount: 5),

        Review(userName: "Selin T.", userAvatar: "👩‍🦳", rating: 5, date: "1 hafta önce",
               comment: "Yeşil menüden aldığım tavuk yemeği muhteşemdi. Hem uygun fiyatlı hem çok lezzetli!",
               ownerReply: "Değerli geri bildiriminiz için teşekkürler! Yeşil Menü'yü beğenmenize çok sevindik.",
               isVerified: false, itemName: "Akşam Özel Tavuk (Green)", helpfulCount: 8),

        Review(userName: "Ahmet D.", userAvatar: "🧔", rating: 3, date: "2 hafta önce",
               comment: "Ortalama bir deneyimdi. Ürün beklediğimden daha küçük geldi.",
               ownerReply: "Geri bildiriminiz için teşekkürler Ahmet Bey, porsiyonlarımızı yeniden değerlendireceğiz.",
               isVerified: true, itemName: "Sezar Salata", helpfulCount: 2),
    ]

    fileprivate let restaurantReviews: [Review] = [
        Review(userName: "Zeynep B.", userAvatar: "👩", rating: 5, date: "3 gün önce",
               comment: "Ortam çok sıcak ve samimi. Personel ilgili ve güleryüzlü. Kadıköy'ün en iyi restoranlarından biri!",
               ownerReply: "Çok teşekkürler Zeynep Hanım, sizi ağırlamak çok güzeldi! 🙏",
               isVerified: true, itemName: nil, helpfulCount: 18),

        Review(userName: "Can Y.", userAvatar: "🧑", rating: 4, date: "1 hafta önce",
               comment: "Fiyat/performans açısından çok iyi. Çocuk dostu ortamı mükemmel. Biraz kalabalık olabiliyor.",
               ownerReply: nil, isVerified: true, itemName: nil, helpfulCount: 7),

        Review(userName: "Nilüfer M.", userAvatar: "👩‍🦱", rating: 5, date: "2 hafta önce",
               comment: "Pet friendly olması harika! Köpeğimle rahatlıkla gelebildim. Özel köpek su kasesi bile verdiler.",
               ownerReply: "Misafirlerimizin tüylü dostlarına her zaman kapımız açık! 🐾",
               isVerified: false, itemName: nil, helpfulCount: 24),

        Review(userName: "Emre K.", userAvatar: "👨‍💼", rating: 2, date: "3 hafta önce",
               comment: "Bekleme süresi çok uzundu. 45 dakika bekledik. Yemekler güzeldi ama bekleme kabul edilemez.",
               ownerReply: "Üzüntüyle karşıladık. Yoğun dönemde yaşanan bu aksiliği telafi etmek için bir sonraki ziyaretinize özel teklif sunmak isteriz.",
               isVerified: true, itemName: nil, helpfulCount: 31),
    ]

    fileprivate var filteredMealReviews: [Review] {
        ratingFilter == 0 ? mealReviews : mealReviews.filter { $0.rating == ratingFilter }
    }
    fileprivate var filteredRestaurantReviews: [Review] {
        ratingFilter == 0 ? restaurantReviews : restaurantReviews.filter { $0.rating == ratingFilter }
    }

    // Ortalama Puan
    fileprivate var avgMealRating: Double {
        Double(mealReviews.map(\.rating).reduce(0, +)) / Double(mealReviews.count)
    }
    fileprivate var avgRestaurantRating: Double {
        Double(restaurantReviews.map(\.rating).reduce(0, +)) / Double(restaurantReviews.count)
    }
    fileprivate var currentAvg: Double {
        selectedSegment == 0 ? avgMealRating : avgRestaurantRating
    }
    fileprivate var currentReviews: [Review] {
        selectedSegment == 0 ? filteredMealReviews : filteredRestaurantReviews
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // MARK: - Rating Özeti
                    RatingSummaryCard(
                        avg: currentAvg,
                        reviews: selectedSegment == 0 ? mealReviews : restaurantReviews
                    )
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // MARK: - Segmented Control
                    Picker("Tür", selection: $selectedSegment.animation()) {
                        Text("Meal Reviews").tag(0)
                        Text("Restaurant Reviews").tag(1)
                    }
                    .pickerStyle(.segmented)
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
                    if currentReviews.isEmpty {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            Text("😶").font(.system(size: 48))
                            Text("Bu puan için yorum bulunamadı")
                                .font(MenuLoTheme.Fonts.body)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                        .padding(.vertical, MenuLoTheme.Spacing.xl)
                    } else {
                        VStack(spacing: MenuLoTheme.Spacing.md) {
                            ForEach(currentReviews) { review in
                                ReviewCard(review: review)
                            }
                        }
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
            .navigationTitle("Reviews & Ratings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWriteSheet) {
                WriteReviewSheet()
            }
        }
    }
}

// MARK: - Rating Özet Kartı
private struct RatingSummaryCard: View {
    let avg: Double
    let reviews: [Review]

    var ratingDistribution: [Int: Int] {
        var dist: [Int: Int] = [5:0, 4:0, 3:0, 2:0, 1:0]
        reviews.forEach { dist[$0.rating, default: 0] += 1 }
        return dist
    }

    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.lg) {

            // Büyük Ortalama
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

            // Dağılım Çubukları
            VStack(spacing: 4) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    HStack(spacing: 6) {
                        Text("\(star)")
                            .font(.caption2)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .frame(width: 12)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(MenuLoTheme.Colors.divider)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(star >= 4 ? .yellow : (star == 3 ? MenuLoTheme.Colors.warning : MenuLoTheme.Colors.error))
                                    .frame(width: geo.size.width * CGFloat(ratingDistribution[star, default: 0]) / CGFloat(reviews.count))
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
    let review: Review
    @State private var isHelpful = false

    var body: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {

            // Kullanıcı Başlığı
            HStack {
                Text(review.userAvatar)
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(MenuLoTheme.Colors.backgroundLight)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(review.userName)
                            .font(MenuLoTheme.Fonts.body)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        if review.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(MenuLoTheme.Colors.primary)
                        }
                    }
                    HStack(spacing: 6) {
                        StarRow(rating: review.rating, size: 12)
                        Text("·")
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        Text(review.date)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }

            // Ürün etiketi (varsa)
            if let itemName = review.itemName {
                Label(itemName, systemImage: "fork.knife")
                    .font(.caption)
                    .foregroundColor(MenuLoTheme.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MenuLoTheme.Colors.primary.opacity(0.1))
                    .clipShape(Capsule())
            }

            // Yorum Metni
            Text(review.comment)
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                .lineSpacing(4)

            // Yararlı Butonu
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) { isHelpful.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isHelpful ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .foregroundColor(isHelpful ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.textSecondary)
                        Text("Yararlı (\(review.helpfulCount + (isHelpful ? 1 : 0)))")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }

            // İşletme Yanıtı (varsa)
            if let reply = review.ownerReply {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.caption)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                        Text("İşletme Yanıtı")
                            .font(MenuLoTheme.Fonts.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                    }
                    Text(reply)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        .lineSpacing(3)
                }
                .padding(MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.primary.opacity(0.06))
                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                .overlay(
                    Rectangle()
                        .fill(MenuLoTheme.Colors.primary)
                        .frame(width: 3)
                        .cornerRadius(2),
                    alignment: .leading
                )
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
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRating = 0
    @State private var comment = ""
    @State private var reviewType = 0  // 0 = Yemek, 1 = Restoran
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    // Tür Seçici
                    Picker("Yorum Türü", selection: $reviewType) {
                        Text("Yemek Yorumu").tag(0)
                        Text("Restoran Yorumu").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // Yıldız Seçici
                    VStack(spacing: MenuLoTheme.Spacing.sm) {
                        Text("Puanınız")
                            .font(MenuLoTheme.Fonts.subtitle)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)

                        HStack(spacing: MenuLoTheme.Spacing.md) {
                            ForEach(1...5, id: \.self) { star in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedRating = star
                                    }
                                } label: {
                                    Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 36))
                                        .scaleEffect(star <= selectedRating ? 1.15 : 1.0)
                                }
                            }
                        }

                        if selectedRating > 0 {
                            Text(ratingLabel)
                                .font(MenuLoTheme.Fonts.caption)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                .transition(.opacity)
                        }
                    }
                    .padding(MenuLoTheme.Spacing.lg)
                    .background(MenuLoTheme.Colors.cardBackground)
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    // Yorum Alanı
                    VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.sm) {
                        Label("Yorumunuz", systemImage: "text.bubble.fill")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        ZStack(alignment: .topLeading) {
                            if comment.isEmpty {
                                Text("Deneyiminizi paylaşın…")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.5))
                                    .padding(MenuLoTheme.Spacing.md)
                            }
                            TextEditor(text: $comment)
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

                    PrimaryButton(
                        title: "Yorumu Gönder",
                        isLoading: isSubmitting
                    ) {
                        isSubmitting = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(selectedRating == 0 || comment.isEmpty)
                    .opacity(selectedRating == 0 || comment.isEmpty ? 0.5 : 1)
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
                    Button("İptal") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
        }
    }

    private var ratingLabel: String {
        switch selectedRating {
        case 1: return "Çok Kötü 😞"
        case 2: return "Kötü 😕"
        case 3: return "Orta 😐"
        case 4: return "İyi 😊"
        case 5: return "Mükemmel 🤩"
        default: return ""
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
    ReviewsView()
}
