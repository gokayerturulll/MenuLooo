//
//  Restaurant.swift
//  MenuLo
//
//  MenuLo/Models/Restaurant.swift
//
//  Restoran veri modeli.
//  Backend tarafındaki PostGIS ve PostgreSQL yapısına uygun olarak tasarlandı.
//

import Foundation
import CoreLocation

struct Restaurant: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String?
    
    // PostGIS ile uyumlu konumsal veriler (Enlem ve Boylam)
    let latitude: Double
    let longitude: Double
    
    // Restorana ait ek bilgiler
    let address: String?
    let coverImageURL: String?
    let averageRating: Double?
    
    // SwiftUI MapKit için CoreLocation koordinat yardımcı değişkeni
    // Bu sayede haritada pin (işaretçi) oluşturmak çok kolay olacak.
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
