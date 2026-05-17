import Foundation
import Combine

@MainActor
final class UserStatsViewModel: ObservableObject {
    @Published private(set) var stats: UserStats?
    @Published private(set) var isLoading = false

    private let network = NetworkManager.shared

    func fetchStats() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            stats = try await network.fetchUserStats()
        } catch {
            // sessizce yoksay — UI placeholder gösterir
        }
    }

    var visitCountText: String {
        guard let s = stats else { return "-" }
        return "\(s.visitCount)"
    }

    var favouriteCountText: String {
        guard let s = stats else { return "-" }
        return "\(s.favouriteCount)"
    }

    var avgRatingText: String {
        guard let s = stats, s.avgRating > 0 else { return "-" }
        return String(format: "%.1f", s.avgRating)
    }

    // İşletme istatistikleri
    var businessAvgRatingText: String {
        guard let b = stats?.business, b.avgRating > 0 else { return "-" }
        return String(format: "%.1f", b.avgRating)
    }

    var businessFavCountText: String {
        guard let b = stats?.business else { return "-" }
        return b.favCount >= 1000
            ? String(format: "%.1fB", Double(b.favCount) / 1000)
            : "\(b.favCount)"
    }
}
