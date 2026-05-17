import Foundation
import CoreLocation
import OSLog

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.menulo", category: "LocationManager")
    private let manager = CLLocationManager()

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        // Restoran keşfi için 100m hassasiyet yeterli; Best kullanmak bataryayı boşaltır.
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // 50 metreden küçük hareketi filtrele — gereksiz güncellemeleri ve ağ isteklerini önler.
        manager.distanceFilter = 50
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        } else {
            userLocation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // CLError.locationUnknown is transient; only log real failures
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        logger.error("Konum alınamadı: \(error.localizedDescription, privacy: .public)")
    }
}
