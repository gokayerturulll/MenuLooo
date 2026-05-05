//
//  LocationManager.swift
//  MenuLo
//
//  MenuLo/Services/LocationManager.swift
//
//  Cihazın GPS konumunu (CoreLocation) yöneten servis.
//  @Observable veya ObservableObject olarak kullanılarak konum değiştiğinde
//  SwiftUI görünümlerini anında günceller.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Apple'ın konum yöneticisi nesnesi
    private let manager = CLLocationManager()
    
    // Kullanıcının anlık konumu (değiştiğinde UI güncellenecek)
    @Published var userLocation: CLLocationCoordinate2D?
    // Kullanıcının konum izni durumu
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        // Navigasyon uygulaması değiliz, o yüzden "best" (en iyi) yerine
        // kilometre bazlı toleranslı bir doğruluk seçebiliriz ama şimdilik en iyi doğrulukla başlıyoruz.
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    /// Kullanıcıdan konum izni ister
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Konum takibini başlatır
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate Metodları
    
    // İzin durumu değiştiğinde tetiklenir
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    // Konum güncellendiğinde tetiklenir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }
    
    // Konum alınamazsa hata verir
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Konum alınamadı: \(error.localizedDescription)")
    }
}
