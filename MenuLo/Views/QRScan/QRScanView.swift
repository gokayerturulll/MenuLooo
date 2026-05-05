//
//  QRScanView.swift
//  MenuLo
//
//  MenuLo/Views/QRScan/QRScanView.swift
//
//  QR Kod tarama sekmesi — Masadaki QR'ı okuyarak menüye anında erişim.
//  Gerçek AVFoundation entegrasyonu için bir sonraki aşamada kamera bağlanacak.
//

import SwiftUI

struct QRScanView: View {

    @State private var isScanning = false
    @State private var scannedCode: String? = nil
    @State private var showResult  = false
    @State private var scanProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Kamera Arka Planı (Mock)
                if isScanning {
                    ScannerPreviewMock()
                        .ignoresSafeArea()
                } else {
                    MenuLoTheme.Colors.backgroundLight
                        .ignoresSafeArea()
                }

                // MARK: - İçerik
                VStack(spacing: MenuLoTheme.Spacing.lg) {

                    if isScanning {
                        // --- Tarama Arayüzü ---
                        Spacer()

                        // Kamera Çerçevesi
                        ZStack {
                            // Arka plan bulanıklık
                            RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                .stroke(.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 260, height: 260)

                            // Köşe işaretleri
                            QRCorners(size: 260)

                            // Tarama çizgisi animasyonu
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            MenuLoTheme.Colors.primary.opacity(0),
                                            MenuLoTheme.Colors.primary,
                                            MenuLoTheme.Colors.primary.opacity(0)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 240, height: 2)
                                .offset(y: -100 + (200 * scanProgress))
                                .animation(
                                    .linear(duration: 1.5).repeatForever(autoreverses: true),
                                    value: scanProgress
                                )
                        }
                        .frame(width: 260, height: 260)
                        .onAppear {
                            scanProgress = 1.0
                            // Simüle: 3 sn sonra QR bulundu
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                scannedCode = "menulo://menu/restaurant/lezzet-duragi"
                                withAnimation { showResult = true }
                                isScanning = false
                            }
                        }

                        Text("QR Kodu Çerçeve İçine Alın")
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, MenuLoTheme.Spacing.xl)
                            .multilineTextAlignment(.center)

                        // İptal
                        Button {
                            withAnimation { isScanning = false }
                        } label: {
                            Text("İptal")
                                .font(MenuLoTheme.Fonts.button)
                                .foregroundColor(.white)
                                .padding(MenuLoTheme.Spacing.md)
                                .background(.white.opacity(0.2))
                                .cornerRadius(MenuLoTheme.CornerRadius.pill)
                        }

                        Spacer()

                    } else if let code = scannedCode, showResult {
                        // --- Tarama Sonucu ---
                        Spacer()

                        VStack(spacing: MenuLoTheme.Spacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(MenuLoTheme.Colors.success.opacity(0.12))
                                    .frame(width: 96, height: 96)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(MenuLoTheme.Colors.success)
                            }
                            .scaleEffect(showResult ? 1 : 0.5)
                            .animation(.spring(response: 0.4), value: showResult)

                            Text("QR Kod Okundu!")
                                .font(MenuLoTheme.Fonts.title)
                                .foregroundColor(MenuLoTheme.Colors.textPrimary)

                            Text("Lezzet Durağı Menüsü")
                                .font(MenuLoTheme.Fonts.subtitle)
                                .foregroundColor(MenuLoTheme.Colors.primary)

                            VStack(spacing: 4) {
                                Text("Masa #7 — Kadıköy Şubesi")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                Text(code)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary.opacity(0.6))
                            }

                            PrimaryButton(title: "Menüyü Görüntüle") {
                                // Menü ekranına git
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                            Button {
                                withAnimation {
                                    scannedCode = nil
                                    showResult = false
                                }
                            } label: {
                                Text("Tekrar Tara")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                            }
                        }
                        .padding(MenuLoTheme.Spacing.lg)
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        Spacer()

                    } else {
                        // --- Başlangıç Ekranı ---
                        Spacer()

                        VStack(spacing: MenuLoTheme.Spacing.lg) {

                            // Animasyonlu İkon
                            ZStack {
                                Circle()
                                    .fill(MenuLoTheme.Colors.primary.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                Circle()
                                    .stroke(MenuLoTheme.Colors.primary.opacity(0.3), lineWidth: 2)
                                    .frame(width: 140, height: 140)

                                Image(systemName: "qrcode")
                                    .font(.system(size: 56))
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                            }

                            VStack(spacing: MenuLoTheme.Spacing.sm) {
                                Text("QR Menü Erişimi")
                                    .font(MenuLoTheme.Fonts.largeTitle)
                                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                                Text("Masanızdaki QR kodu okutarak\nmenüye saniyeler içinde erişin.")
                                    .font(MenuLoTheme.Fonts.body)
                                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                            }

                            // Özellik Kartları
                            HStack(spacing: MenuLoTheme.Spacing.md) {
                                FeatureCard(icon: "bolt.fill", color: MenuLoTheme.Colors.primary, label: "Hızlı Erişim")
                                FeatureCard(icon: "hand.point.up.left.fill", color: MenuLoTheme.Colors.success, label: "Kolay Sipariş")
                                FeatureCard(icon: "leaf.fill", color: Color(hex: "#00B894"), label: "Yeşil Menü")
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)

                            PrimaryButton(title: "Kamerayı Başlat") {
                                withAnimation { isScanning = true }
                            }
                            .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        }

                        Spacer()
                    }
                }
            }
            .navigationTitle(isScanning ? "" : "QR Scan")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - QR Köşe Bileşeni
private struct QRCorners: View {
    let size: CGFloat
    let cornerLength: CGFloat = 24
    let lineWidth: CGFloat = 4

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                CornerShape(position: i, length: cornerLength)
                    .stroke(MenuLoTheme.Colors.primary, lineWidth: lineWidth)
                    .frame(width: size, height: size)
            }
        }
    }
}

private struct CornerShape: Shape {
    let position: Int  // 0=TL, 1=TR, 2=BL, 3=BR
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch position {
        case 0: // Top-Left
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        case 1: // Top-Right
            path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        case 2: // Bottom-Left
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        case 3: // Bottom-Right
            path.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        default: break
        }
        return path
    }
}

// MARK: - Kamera Mock Önizleme
private struct ScannerPreviewMock: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
            // Sahte kamera noktaları
            VStack(spacing: 40) {
                ForEach(0..<6, id: \.self) { _ in
                    HStack(spacing: 40) {
                        ForEach(0..<8, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(Double.random(in: 0.02...0.08)))
                                .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Özellik Kartı
private struct FeatureCard: View {
    let icon: String
    let color: Color
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            Text(label)
                .font(.caption2)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MenuLoTheme.Spacing.md)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    QRScanView()
}
