//
//  DiscoverView.swift
//  MenuLo
//
//  MenuLo/Views/Discover/DiscoverView.swift
//
//  Tam ekran harita ve üstte arama çubuğu barındıran Ana Keşfet Ekranı.
//

import SwiftUI
import MapKit

struct DiscoverView: View {
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var searchText = ""
    
    // Haritanın başlangıç konumu (Örn: Kadıköy)
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.990, longitude: 29.025),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            // 1. Arka Planda Tam Ekran Harita
            Map(coordinateRegion: $mapRegion, showsUserLocation: true, annotationItems: viewModel.restaurants) { restaurant in
                // Harita üzerindeki her restoran için özel bir pin (işaretçi)
                MapAnnotation(coordinate: restaurant.coordinate) {
                    VStack {
                        Image(systemName: "fork.knife.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .background(Color.white)
                            .clipShape(Circle())
                            // Hafif gölge ile pin'i belirginleştiriyoruz
                            .shadow(radius: 3)
                        
                        Text(restaurant.name)
                            .font(MenuLoTheme.Fonts.caption)
                            .padding(4)
                            .background(MenuLoTheme.Colors.cardBackground.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
            .ignoresSafeArea(edges: .top) // Üst barın altına kadar haritayı genişlet
            
            // 2. Üstte Yüzen (Floating) Arama Çubuğu
            VStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    
                    TextField("Mekan veya lezzet ara...", text: $searchText)
                        .font(MenuLoTheme.Fonts.body)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        }
                    }
                }
                .padding()
                // Glassmorphism Etkisi: Yarı saydam beyaz arka plan + bulanıklık (Material)
                .background(.regularMaterial)
                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, MenuLoTheme.Spacing.md)
                .padding(.top, MenuLoTheme.Spacing.sm)
                
                Spacer()
                
                // Konumuma Git Butonu (Sağ Altta)
                HStack {
                    Spacer()
                    Button(action: {
                        if let userLoc = viewModel.userLocation {
                            withAnimation {
                                mapRegion.center = userLoc
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(MenuLoTheme.Colors.primary)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, MenuLoTheme.Spacing.md)
                    .padding(.bottom, MenuLoTheme.Spacing.lg)
                }
            }
        }
        .onAppear {
            // Ekran açıldığında restoranları backend'den (şu an mock) çek
            Task {
                await viewModel.fetchNearbyRestaurants()
            }
        }
    }
}
