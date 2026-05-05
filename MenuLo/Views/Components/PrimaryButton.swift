//
//  PrimaryButton.swift
//  MenuLo
//
//  MenuLo/Views/Components/PrimaryButton.swift
//
//  Uygulamanın standart birincil eylem butonu.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void
    
    // Varsayılan değerler atıyoruz
    init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(MenuLoTheme.Fonts.button)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            // Butonun yüksekliği ve iç boşlukları Apple HIG standartlarına uygun
            .padding(.vertical, MenuLoTheme.Spacing.md) 
            .background(MenuLoTheme.Colors.primary)
            .cornerRadius(MenuLoTheme.CornerRadius.pill)
            // Butona hafif bir gölge ekleyerek tıklanabilir olduğunu hissettiriyoruz (UX)
            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading) // Yüklenirken çift tıklamayı önle
    }
}
