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

@MainActor
class DiscoverViewModel: ObservableObject {
    
    // Ekranda listelenecek veya haritada gösterilecek restoranlar
    @Published var restaurants: [Restaurant] = []
    
    // Cihaz konumunu almak için oluşturduğumuz servisi çağırıyoruz
    @Published var locationManager = LocationManager()
    
    // API isteği yapılırken ekranda bir yüklenme ikonu göstermek için
    @Published var isLoading = false
    
    init() {
        // ViewModel ilk yaratıldığında otomatik olarak konum izni isteyip
        // takibi başlatabiliriz.
        locationManager.requestPermission()
    }
    
    /// Kullanıcının mevcut konumunu LocationManager üzerinden dışarıya verir
    var userLocation: CLLocationCoordinate2D? {
        locationManager.userLocation
    }
    
    /// Backend'den (Node.js) kullanıcının konumuna göre restoranları çeker
    func fetchNearbyRestaurants() async {
        // Konum yoksa arama yapamayız
        guard let location = userLocation else {
            print("Konum henüz alınamadı.")
            return
        }
        
        isLoading = true
        
        // TODO: İleride NetworkManager üzerinden `GET /api/restaurants?lat=x&lng=y`
        // isteğini atacağımız yer burası.
        
        // Şimdilik sahte (Mock) veri ile dolduruyoruz
        // Force unwrap kullanmıyoruz (kurallara uygun).
        let mockData = [
            Restaurant(id: UUID(), name: "Mamma Mia Pizzeria", description: "İtalyan Lezzetleri", latitude: location.latitude + 0.001, longitude: location.longitude + 0.001, address: "Kadıköy, İstanbul", coverImageURL: nil, averageRating: 4.8),
            Restaurant(id: UUID(), name: "Green Burger", description: "Vegan Fast Food", latitude: location.latitude - 0.002, longitude: location.longitude + 0.0015, address: "Moda, İstanbul", coverImageURL: nil, averageRating: 4.5)
        ]
        
        // Simüle edilmiş ağ gecikmesi
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
            self.restaurants = mockData
            self.isLoading = false
        } catch {
            print("Veri çekme hatası: \(error)")
            self.isLoading = false
        }
    }
}
