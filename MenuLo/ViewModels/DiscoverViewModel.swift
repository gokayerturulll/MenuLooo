import Foundation
import CoreLocation
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {

    @Published var restaurants: [Restaurant] = []
    @Published var locationManager = LocationManager()
    @Published var isLoading = false
    @Published var fetchError: String? = nil
    @Published var filter: RestaurantFilter = RestaurantFilter()

    private var cancellables = Set<AnyCancellable>()

    init() {
        locationManager.requestPermission()
        setupLocationSubscription()
    }

    private func setupLocationSubscription() {
        locationManager.$userLocation
            .compactMap { $0 }
            .removeDuplicates { lhs, rhs in
                let a = CLLocation(latitude: lhs.latitude, longitude: lhs.longitude)
                let b = CLLocation(latitude: rhs.latitude, longitude: rhs.longitude)
                return a.distance(from: b) < 50
            }
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    // Konum güncellendiğinde distance_m'i tazelemek için zorla yenile.
                    await self?.fetchNearbyRestaurants(forceRefresh: true)
                }
            }
            .store(in: &cancellables)
    }

    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }

    func fetchNearbyRestaurants(forceRefresh: Bool = false) async {
        if isLoading { return }
        if !forceRefresh && !restaurants.isEmpty { return }

        isLoading = true
        fetchError = nil
        defer { isLoading = false }

        do {
            let fetched = try await NetworkManager.shared.fetchRestaurants(
                filter: filter,
                userLocation: locationManager.userLocation
            )
            self.restaurants = fetched
        } catch {
            self.fetchError = error.localizedDescription
        }
    }

    /// Filtre çekmecesinden dönen yeni durumu uygular ve listeyi yeniden yükler.
    func applyFilter(_ newFilter: RestaurantFilter) async {
        filter = newFilter
        await fetchNearbyRestaurants(forceRefresh: true)
    }

    func refresh() async {
        await fetchNearbyRestaurants(forceRefresh: true)
    }

    func clearError() {
        fetchError = nil
    }

    /// Sadece restoran adı üzerinde case-insensitive arama.
    func searchResults(for query: String, limit: Int = 10) -> [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return restaurants
            .filter { $0.businessName.localizedCaseInsensitiveContains(trimmed) }
            .prefix(limit)
            .map { $0 }
    }
}
