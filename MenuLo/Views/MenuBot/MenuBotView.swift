//
//  MenuBotView.swift
//  MenuLo
//
//  AI Chatbot (MenuBot) sekmesi — Yapay zeka destekli menü önerileri.
//  iMessage benzeri sohbet arayüzü olacak.
//  İlerleyen aşamalarda Python backend ile entegre edilecek.
//

import SwiftUI

struct MenuBotView: View {
    
    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()
                
                VStack(spacing: MenuLoTheme.Spacing.lg) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 64))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    
                    Text("MenuBot")
                        .font(MenuLoTheme.Fonts.title)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    
                    Text("Bütçene ve damak tadına göre\nkişiselleştirilmiş menü önerileri al.\nYapay zeka asistanın her zaman yanında!")
                        .font(MenuLoTheme.Fonts.body)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Label("AI Chat entegrasyonu bir sonraki aşamada", systemImage: "hammer.fill")
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(MenuLoTheme.Colors.warning)
                        .padding()
                        .background(
                            MenuLoTheme.Colors.warning.opacity(0.1)
                                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        )
                }
            }
            .navigationTitle("MenuBot")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    MenuBotView()
}
