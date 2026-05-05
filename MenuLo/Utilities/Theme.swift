//
//  Theme.swift
//  MenuLo
//
//  Uygulama genelinde kullanılan renk paleti, tipografi ve tasarım sabitleri.
//  Tüm View'larda tutarlı görünüm için bu dosyadaki değerler kullanılır.
//

import SwiftUI

// MARK: - MenuLo Tema Tanımları

/// Uygulama genelinde kullanılan renk ve tipografi sabitleri.
///
/// Kullanım:
/// ```swift
/// Text("Başlık")
///     .font(MenuLoTheme.Fonts.title)
///     .foregroundColor(MenuLoTheme.Colors.primary)
/// ```
struct MenuLoTheme {
    
    // MARK: - Renkler
    
    /// Uygulama renk paleti.
    struct Colors {
        /// Ana marka rengi — turuncu (#FFA63B)
        static let primary = Color(hex: "#FFA63B")
        
        /// Koyu arka plan (Dark Mode uyumlu)
        static let backgroundDark = Color(hex: "#1A1A2E")
        
        /// Açık arka plan
        static let backgroundLight = Color(hex: "#F8F9FA")
        
        /// Ana metin rengi
        static let textPrimary = Color(hex: "#2D3436")
        
        /// İkincil metin rengi (açıklamalar, alt başlıklar)
        static let textSecondary = Color(hex: "#636E72")
        
        /// Başarı rengi (yeşil — Green Menu vb.)
        static let success = Color(hex: "#00B894")
        
        /// Uyarı rengi
        static let warning = Color(hex: "#FDCB6E")
        
        /// Hata rengi
        static let error = Color(hex: "#E17055")
        
        /// Kart arka plan rengi
        static let cardBackground = Color(hex: "#FFFFFF")
        
        /// Ayırıcı çizgi rengi
        static let divider = Color(hex: "#DFE6E9")
    }
    
    // MARK: - Tipografi (Gabarito Font Ailesi)
    
    /// Gabarito font ailesi yardımcıları.
    ///
    /// **Önemli:** Bu fontların çalışması için:
    /// 1. `.ttf` dosyalarını `Resources/Fonts/` klasörüne ekleyin
    /// 2. Xcode'da "Build Phases > Copy Bundle Resources"a ekleyin
    /// 3. `Info.plist`'e `UIAppFonts` (Fonts provided by application) key'i altında
    ///    font dosya isimlerini listeleyin
    struct Fonts {
        
        /// Gabarito fontunu belirtilen boyut ve ağırlıkla döndürür.
        /// Font projeye henüz eklenmemişse sistem fontuna düşer (fallback).
        static func gabarito(size: CGFloat, weight: GabaritoWeight = .regular) -> Font {
            return .custom(weight.fontName, size: size)
        }
        
        /// Gabarito font ağırlıkları
        enum GabaritoWeight: String {
            case regular   = "Gabarito-Regular"
            case medium    = "Gabarito-Medium"
            case semiBold  = "Gabarito-SemiBold"
            case bold      = "Gabarito-Bold"
            
            var fontName: String { self.rawValue }
        }
        
        // — Hazır Font Stilleri —
        
        /// Büyük başlık (28pt, Bold)
        static let largeTitle = gabarito(size: 28, weight: .bold)
        
        /// Başlık (22pt, SemiBold)
        static let title = gabarito(size: 22, weight: .semiBold)
        
        /// Alt başlık (18pt, Medium)
        static let subtitle = gabarito(size: 18, weight: .medium)
        
        /// Gövde metni (16pt, Regular)
        static let body = gabarito(size: 16, weight: .regular)
        
        /// Küçük metin (14pt, Regular)
        static let caption = gabarito(size: 14, weight: .regular)
        
        /// Buton metni (16pt, SemiBold)
        static let button = gabarito(size: 16, weight: .semiBold)
    }
    
    // MARK: - Boyut Sabitleri
    
    /// Arayüz boşluk ve boyut sabitleri
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    /// Köşe yuvarlama değerleri
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 24
    }
}
