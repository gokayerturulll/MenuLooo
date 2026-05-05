//
//  ProfileView.swift
//  MenuLo
//
//  Profil ve Ayarlar sekmesi — Kullanıcı bilgileri ve çıkış yapma.
//  İlerleyen aşamalarda favoriler, sipariş geçmişi ve ayarlar eklenecek.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()
                
                VStack(spacing: MenuLoTheme.Spacing.lg) {
                    
                    // MARK: - Profil Avatarı
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(MenuLoTheme.Colors.primary)
                    
                    // Kullanıcı bilgileri
                    if let user = authViewModel.currentUser {
                        Text(user.name)
                            .font(MenuLoTheme.Fonts.title)
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        
                        Text(user.email)
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                        
                        // Kullanıcı tipi rozeti
                        Text(user.userType.displayName)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, MenuLoTheme.Spacing.md)
                            .padding(.vertical, MenuLoTheme.Spacing.xs)
                            .background(MenuLoTheme.Colors.primary)
                            .cornerRadius(MenuLoTheme.CornerRadius.pill)
                    }
                    
                    Spacer()
                    
                    // MARK: - Çıkış Butonu
                    Button {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Çıkış Yap")
                                .font(MenuLoTheme.Fonts.button)
                        }
                        .foregroundColor(MenuLoTheme.Colors.error)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            MenuLoTheme.Colors.error.opacity(0.1)
                                .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, MenuLoTheme.Spacing.xl)
                }
                .padding(.top, MenuLoTheme.Spacing.xl)
            }
            .navigationTitle("Profil")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
}
