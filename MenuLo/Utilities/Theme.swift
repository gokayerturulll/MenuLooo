//
//  Theme.swift
//  MenuLo
//
//  Uygulama genelinde kullanılan renk paleti, tipografi ve tasarım sabitleri.
//  Tüm View'larda tutarlı görünüm için bu dosyadaki değerler kullanılır.
//

import SwiftUI
import UIKit

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
    ///
    /// **Brand renkleri** (primary, success, warning, error) sabittir — marka kimliği
    /// her iki modda aynı kalır.
    /// **Semantic renkler** (background, card, text, divider) iOS sistem trait'ine
    /// göre otomatik olarak light ↔ dark arasında geçiş yapar.
    struct Colors {

        // MARK: Brand (sabit, marka kimliği)

        /// Ana marka rengi — turuncu (#FFA63B)
        static let primary = Color(hex: "#FFA63B")

        /// Başarı rengi (yeşil — Green Menu vb.)
        static let success = Color(hex: "#00B894")

        /// Uyarı rengi
        static let warning = Color(hex: "#FDCB6E")

        /// Hata rengi
        static let error = Color(hex: "#E17055")

        // MARK: Semantic (light/dark adaptive)

        /// Sayfa arka planı — açık modda neredeyse beyaz, koyu modda neredeyse siyah
        static let backgroundLight = adaptive(light: "#F8F9FA", dark: "#0F1116")

        /// Kart arka planı — açık modda saf beyaz, koyu modda elevated yüzey
        static let cardBackground = adaptive(light: "#FFFFFF", dark: "#1C1C1E")

        /// Ana metin rengi — açık modda koyu, koyu modda neredeyse beyaz
        static let textPrimary = adaptive(light: "#2D3436", dark: "#F2F2F7")

        /// İkincil metin rengi (açıklamalar, alt başlıklar)
        static let textSecondary = adaptive(light: "#636E72", dark: "#98989F")

        /// Ayırıcı çizgi rengi
        static let divider = adaptive(light: "#DFE6E9", dark: "#38383A")

        /// Geriye dönük uyum: bazı view'lar `backgroundDark`'ı doğrudan referans
        /// ediyor olabilir. Yeni adaptive `backgroundLight`'a yönlendirildi.
        static let backgroundDark = backgroundLight

        // MARK: Helpers

        /// Bir UIColor closure üzerinden iki hex string arasında otomatik
        /// light/dark seçimi yapan SwiftUI Color üretir.
        private static func adaptive(light: String, dark: String) -> Color {
            Color(uiColor: UIColor { trait in
                UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
            })
        }
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
