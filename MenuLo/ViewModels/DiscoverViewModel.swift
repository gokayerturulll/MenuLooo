//
//  DiscoverViewModel.swift
//  MenuLo
//
//  MenuLo/ViewModels/DiscoverViewModel.swift
//
//  Keşfet ve Harita ekranının iş mantığını (Business Logic) yöneten ViewModel.
//  @MainActor: Tüm UI güncellemelerinin ana iş parçacığında (Main Thread) yapılmasını garanti eder.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class DiscoverViewModel: ObservableObject {

    // Ekranda listelenecek veya haritada gösterilecek restoranlar
    @Published var restaurants: [Restaurant] = []

    // Cihaz konumunu almak için oluşturduğumuz servisi çağırıyoruz
    @Published var locationManager = LocationManager()

    // API isteği yapılırken ekranda bir yüklenme ikonu göstermek için
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()

    // İlk başarılı fetch'ten sonra otomatik konum-tetiklemeli refetch'i
    // sadece konum belirgin şekilde değiştiğinde yapmak için flag.
    private var hasLoadedOnce = false

    init() {
        locationManager.requestPermission()
        setupLocationSubscription()
    }

    private func setupLocationSubscription() {
        // Konum stream'i çok sık tetikleniyor (simülatörde saniyede onlarca olay).
        // 1) 50 m altı değişimleri yoksay → minik GPS jitter'ı fetch tetiklemesin
        // 2) 1.5 sn debounce → ardışık güncellemelerin sonuncusunu al
        // 3) fetch'in kendi guard'ı zaten dolu liste varsa skip ediyor
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
                    await self?.fetchNearbyRestaurants()
                }
            }
            .store(in: &cancellables)
    }

    /// Kullanıcının mevcut konumunu LocationManager üzerinden dışarıya verir
    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }

    /// Backend'den (Node.js) kullanıcının konumuna göre restoranları çeker.
    ///
    /// Idempotent: çağrıldığında zaten yükleme varsa veya cache doluysa
    /// API'ye gitmez. Sonsuz döngüye karşı koruma `forceRefresh: true` ile aşılabilir
    /// (pull-to-refresh / kullanıcı manuel "Yenile" gibi durumlar için).
    func fetchNearbyRestaurants(forceRefresh: Bool = false) async {
        if isLoading { return }
        if !forceRefresh && !restaurants.isEmpty { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await NetworkManager.shared.fetchRestaurants()
            self.restaurants = fetched
            self.hasLoadedOnce = true
        } catch {
            print("Veri çekme hatası: \(error)")
        }
    }

    /// Pull-to-refresh / manuel yenile için public entry-point.
    /// Cache guard'ını es geçer ve yeniden fetch'ler.
    func refresh() async {
        await fetchNearbyRestaurants(forceRefresh: true)
    }

    /// Arama çubuğu için: SADECE restoranın adı (businessName) üzerinde
    /// case-insensitive eşleşme. Adres ve mutfak alanları kasıtlı olarak
    /// kapsam dışında — kullanıcı "ataşehir" yazdığında adında bu kelime
    /// geçen yerler dönsün, adresi Ataşehir olan kebapçılar dönmesin.
    /// Boş query'de boş dizi döner.
    func searchResults(for query: String, limit: Int = 10) -> [Restaurant] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return restaurants
            .filter { $0.businessName.localizedCaseInsensitiveContains(trimmed) }
            .prefix(limit)
            .map { $0 }
    }
}
