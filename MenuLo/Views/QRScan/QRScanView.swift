//
//  QRScanView.swift
//  MenuLo
//
//  MenuLo/Views/QRScan/QRScanView.swift
//
//  Grup Karar Odası için QR kod okuma ve gösterme ekranı.
//

import SwiftUI

struct QRScanView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var selectedTab = 0 // 0: QR Okut, 1: QR Göster
    @State private var scanProgress: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // MARK: - Segmented Control
                    Picker("İşlem", selection: $selectedTab) {
                        Text("QR Okut").tag(0)
                        Text("QR Göster").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .padding(.top, MenuLoTheme.Spacing.md)
                    .padding(.bottom, MenuLoTheme.Spacing.lg)
                    .onChange(of: selectedTab) { newValue in
                        if newValue == 0 {
                            cameraManager.startSession()
                        } else {
                            cameraManager.stopSession()
                        }
                    }

                    if selectedTab == 0 {
                        // MARK: - QR Okut (Odaya Katıl)
                        qrScanTab()
                    } else {
                        // MARK: - QR Göster (Oda Kur)
                        qrShowTab()
                    }
                }
            }
            .navigationTitle("Grup Karar Odası")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraManager.requestPermission()
                // Kamera setup için biraz bekleyelim ki izin popup'ı geçebilsin
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if cameraManager.permissionGranted {
                        cameraManager.setupCamera()
                        if selectedTab == 0 {
                            cameraManager.startSession()
                        }
                    }
                }
            }
            .onDisappear {
                cameraManager.stopSession()
            }
        }
    }

    // MARK: - Tab: QR Okut
    @ViewBuilder
    private func qrScanTab() -> some View {
        VStack {
            ZStack {
                // Kamera Görüntüsü
                if cameraManager.permissionGranted {
                    CameraPreviewView(cameraManager: cameraManager)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.black.opacity(0.8))
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                        .overlay(
                            Text("Kamera izni gerekiyor")
                                .foregroundColor(.white)
                                .font(MenuLoTheme.Fonts.body)
                        )
                }

                // QR Tarama Çerçevesi
                ZStack {
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                        .stroke(.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 260, height: 260)

                    QRCorners(size: 260)

                    // Tarama Çizgisi Animasyonu
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
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                                scanProgress = 1.0
                            }
                        }
                }
                
                // Başarılı Tarama Durumu (Demo)
                if let code = cameraManager.scannedCode {
                    VStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(MenuLoTheme.Colors.success)
                                .font(.system(size: 40))
                            Text("QR Okundu: \(code.prefix(10))...")
                                .font(MenuLoTheme.Fonts.caption)
                                .foregroundColor(MenuLoTheme.Colors.textPrimary)
                            Button("Tekrar Dene") {
                                cameraManager.scannedCode = nil
                                cameraManager.startSession()
                            }
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .font(MenuLoTheme.Fonts.button)
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(MenuLoTheme.Colors.cardBackground)
                        .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        .shadow(radius: 10)
                        .padding(.bottom, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            Text("Arkadaşının odasına katılmak için QR'ı okut")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, MenuLoTheme.Spacing.xl)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }

    // MARK: - Tab: QR Göster
    @ViewBuilder
    private func qrShowTab() -> some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            
            Spacer()
            
            Text("Oda Kuruldu 🎉")
                .font(MenuLoTheme.Fonts.title)
                .foregroundColor(MenuLoTheme.Colors.textPrimary)
            
            // Mock QR Kod
            ZStack {
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
                
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.black)
                
                // Logo ortada
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(MenuLoTheme.Colors.primary)
            }
            
            Text("Arkadaşların odaya katılmak için bu kodu okutabilir")
                .font(MenuLoTheme.Fonts.body)
                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MenuLoTheme.Spacing.xl)
            
            Spacer()
            
            PrimaryButton(title: "Odayı Başlat") {
                // Odayı başlatma aksiyonu
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .padding(.bottom, MenuLoTheme.Spacing.xl)
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

// MARK: - Preview
#Preview {
    QRScanView()
}
