//
//  CustomTextField.swift
//  MenuLo
//
//  MenuLo/Views/Components/CustomTextField.swift
//
//  İkon destekli, standart görünümlü metin ve şifre giriş alanı.
//

import SwiftUI

struct CustomTextField: View {
    let placeholder: String
    let iconName: String
    @Binding var text: String
    var isSecure: Bool = false
    
    @State private var isPasswordVisible: Bool = false
    
    var body: some View {
        HStack(spacing: MenuLoTheme.Spacing.sm) {
            // Sol taraftaki ikon
            Image(systemName: iconName)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .frame(width: 24)
            
            // Şifre mi yoksa normal metin mi?
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            
            // Eğer şifre alanıysa göz ikonunu göster
            if isSecure {
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                }
            }
        }
        .padding()
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.medium)
        // Giriş kutusuna derinlik katan hafif gölge
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
