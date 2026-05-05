//
//  RoomListView.swift
//  MenuLo
//
//  Karar Odaları sekmesi — Arkadaş gruplarıyla ortak yemek kararı.
//  İlerleyen aşamalarda Socket.io ile gerçek zamanlı oda etkileşimi eklenecek.
//

import SwiftUI

struct RoomListView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()
                
                VStack(spacing: MenuLoTheme.Spacing.lg) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 64))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    
                    Text("Karar Odaları")
                        .font(MenuLoTheme.Fonts.title)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    
                    Text("Arkadaşlarınla oda oluştur,\nortak bütçe ve diyet tercihlerinize göre\nen uygun mekanı birlikte seçin.")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Label("Socket.io entegrasyonu bir sonraki aşamada", systemImage: "hammer.fill")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.warning)
                        .padding()
                        .background(
                            MenuLoTheme.Colors.warning.opacity(0.1)
                                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        )
                }
            }
            .navigationTitle("Odalar")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    RoomListView()
}
