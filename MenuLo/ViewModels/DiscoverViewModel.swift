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
    
    init() {
        locationManager.requestPermission()
        setupLocationSubscription()
    }
    
    private func setupLocationSubscription() {
        // Kullanıcı konumu her güncellendiğinde restoranları otomatik olarak çekiyoruz
        locationManager.$userLocation
            .compactMap { $0 }
            .debounce(for: .seconds(1.5), scheduler: RunLoop.main) // API spamını engellemek için debounce
            .sink { [weak self] _ in
                Task {
                    await self?.fetchNearbyRestaurants()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Kullanıcının mevcut konumunu LocationManager üzerinden dışarıya verir
    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    /// Backend'den (Node.js) kullanıcının konumuna göre restoranları çeker
    func fetchNearbyRestaurants() async {
        isLoading = true
        
        // Gerçek backend API'sinden restoranları çekiyoruz
        do {
            let fetched = try await NetworkManager.shared.fetchRestaurants()
            self.restaurants = fetched
            self.isLoading = false
        } catch {
            print("Veri çekme hatası: \(error)")
            self.isLoading = false
        }
    }
}
