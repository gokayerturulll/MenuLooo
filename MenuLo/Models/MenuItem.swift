//
//  MenuItem.swift
//  MenuLo
//
//  MenuLo/Models/MenuItem.swift
//
//  Restoran menüsündeki ürünleri temsil eden veri modeli.
//  Backend'deki pgvector ve yapay zeka arama altyapısına uygun tasarlanmıştır.
//

import Foundation

struct MenuItem: Identifiable, Codable {
    let id: UUID
    let restaurantId: UUID
    let name: String
    let description: String?
    let price: Double
    
    // Green Menu (Gıda İsrafı Önleme) Özellikleri
    let isGreenMenu: Bool
    let greenPrice: Double?
    
    // Diyet tercihleri (Filtreleme için)
    let isVegan: Bool?
    let isVegetarian: Bool?
    
    // Not: Yapay zeka vektörleri (embeddings) genellikle veritabanında (pgvector)
    // tutulur ve arama işlemi sunucuda gerçekleşir. Ancak ileride cihaz içi (on-device)
    // yapay zeka kullanılacaksa diye vektör dizisini opsiyonel olarak tanımlıyoruz.
    let searchVector: [Double]?
}
