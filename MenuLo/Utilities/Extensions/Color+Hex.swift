//
//  Color+Hex.swift
//  MenuLo
//
//  SwiftUI Color struct'ına hex string desteği ekleyen extension.
//  Kullanım: Color(hex: "#FFA63B") veya Color(hex: "FFA63B")
//

import SwiftUI

extension Color {
    
    /// Hex string'den SwiftUI Color oluşturur.
    ///
    /// - Parameter hex: "#FFA63B" veya "FFA63B" formatında hex renk kodu.
    ///   Opsiyonel olarak alpha değeri için 8 karakter de kabul eder (örn: "FFA63BFF").
    ///
    /// Örnek Kullanım:
    /// ```swift
    /// Text("Merhaba")
    ///     .foregroundColor(Color(hex: "#FFA63B"))
    /// ```
    init(hex: String) {
        // "#" işaretini temizle
        let cleanedHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        // Hex string'i UInt64'e çevir
        var rgbValue: UInt64 = 0
        Scanner(string: cleanedHex).scanHexInt64(&rgbValue)
        
        // 8 karakterli hex → RGBA, 6 karakterli hex → RGB (alpha = 1.0)
        let red, green, blue, alpha: Double
        
        switch cleanedHex.count {
        case 8: // RRGGBBAA
            red   = Double((rgbValue >> 24) & 0xFF) / 255.0
            green = Double((rgbValue >> 16) & 0xFF) / 255.0
            blue  = Double((rgbValue >> 8)  & 0xFF) / 255.0
            alpha = Double(rgbValue & 0xFF) / 255.0
        case 6: // RRGGBB
            red   = Double((rgbValue >> 16) & 0xFF) / 255.0
            green = Double((rgbValue >> 8)  & 0xFF) / 255.0
            blue  = Double(rgbValue & 0xFF) / 255.0
            alpha = 1.0
        default:
            red = 0; green = 0; blue = 0; alpha = 1.0
        }
        
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
