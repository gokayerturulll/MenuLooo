//
//  DiscoverView.swift
//  MenuLo
//
//  Keşfet sekmesi — Harita ve restoran arama ekranı.
//  İlerleyen aşamalarda MapKit, CoreLocation ve QR tarayıcı entegre edilecek.
//

import SwiftUI

struct DiscoverView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()
                
                VStack(spacing: MenuLoTheme.Spacing.lg) {
                    // Placeholder İkon
                    Image(systemName: "map.fill")
                        .font(.system(size: 64))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    
                    Text("Keşfet")
                        .font(MenuLoTheme.Fonts.title)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    
                    Text("Yakınındaki restoranları haritada keşfet,\nQR kod ile menüye anında eriş.")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // İlerleme göstergesi
                    Label("Harita entegrasyonu bir sonraki aşamada", systemImage: "hammer.fill")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.warning)
                        .padding()
                        .background(
                            MenuLoTheme.Colors.warning.opacity(0.1)
                                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        )
                }
            }
            .navigationTitle("Keşfet")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    DiscoverView()
}
