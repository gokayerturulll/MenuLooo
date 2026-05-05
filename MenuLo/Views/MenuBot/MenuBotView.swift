//
//  MenuBotView.swift
//  MenuLo
//
//  AI Chatbot (MenuBot) — Sparkles FAB'dan açılır, tam ekran cover.
//  İlerleyen aşamalarda Python backend ile entegre edilecek.
//

import SwiftUI

struct MenuBotView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient arkaplan
                LinearGradient(
                    colors: [
                        MenuLoTheme.Colors.primary.opacity(0.08),
                        MenuLoTheme.Colors.backgroundLight
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: MenuLoTheme.Spacing.xl) {

                    Spacer()

                    // Ana İkon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MenuLoTheme.Colors.primary, Color(hex: "#FF6B35")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.4), radius: 20)

                        Image(systemName: "sparkles")
                            .font(.system(size: 46, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    // Başlık + Açıklama
                    VStack(spacing: MenuLoTheme.Spacing.sm) {
                        Text("MenuBot")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)

                        Text("Bütçene ve damak tadına göre\nkişiselleştirilmiş menü önerileri al.\nYapay zeka asistanın her zaman yanında!")
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }

                    // Yakında Banner
                    HStack(spacing: MenuLoTheme.Spacing.sm) {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(MenuLoTheme.Colors.warning)
                        Text("AI Chat entegrasyonu bir sonraki aşamada geliyor")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.warning)
                    }
                    .padding(MenuLoTheme.Spacing.md)
                    .background(MenuLoTheme.Colors.warning.opacity(0.1))
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)

                    Spacer()

                    // Kapat Butonu
                    Button { dismiss() } label: {
                        HStack(spacing: MenuLoTheme.Spacing.sm) {
                            Image(systemName: "xmark")
                            Text("Kapat")
                                .font(MenuLoTheme.Fonts.button)
                        }
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(MenuLoTheme.Spacing.md)
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .shadow(color: .black.opacity(0.06), radius: 6)
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
            }
            .navigationTitle("MenuBot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(MenuLoTheme.Colors.textSecondary)
                            .font(.title3)
                    }
                }
            }
        }
    }
}

#Preview {
    MenuBotView()
}
