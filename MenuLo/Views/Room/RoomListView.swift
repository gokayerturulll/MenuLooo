import SwiftUI
import AVFoundation
import UIKit

// MARK: - RoomListView

struct RoomListView: View {

    @EnvironmentObject private var viewModel:       RoomViewModel
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @State private var showCreatedRoom    = false
    @State private var showActiveRoom     = false
    @State private var goToLobby          = false
    @State private var selectedTab: QRTab = .show
    @State private var pinInput           = ""
    @State private var shouldResetScanner = false
    @State private var scanProgress: CGFloat = 0
    @State private var cameraPermission   = AVCaptureDevice.authorizationStatus(for: .video)

    enum QRTab { case show, scan }

    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Başlık
                    VStack(spacing: 6) {
                        Text("Karar Odası")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        Text(selectedTab == .show
                             ? "QR kodunu arkadaşına göster"
                             : "QR kodunu cihaza okut")
                            .font(MenuLoTheme.Fonts.body)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 20)

                    // Üst segment
                    topSegment
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, 24)

                    // İçerik
                    if selectedTab == .show {
                        showContent
                    } else {
                        scanContent
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear { handlePendingRoomDeepLink() }
            .onChange(of: deepLinkRouter.pending) { _ in handlePendingRoomDeepLink() }
            .fullScreenCover(isPresented: $showCreatedRoom, onDismiss: {
                if goToLobby { goToLobby = false; showActiveRoom = true }
            }) {
                if let room = viewModel.currentRoom {
                    CreatedRoomView(room: room) {
                        goToLobby = true; showCreatedRoom = false
                    }
                    .environmentObject(viewModel)
                }
            }
            .sheet(isPresented: $showActiveRoom) {
                if let room = viewModel.currentRoom {
                    ActiveRoomView(room: room) {
                        showActiveRoom = false
                        viewModel.leaveCurrentRoom()
                    }
                    .environmentObject(viewModel)
                }
            }
        }
    }

    // MARK: - Üst Segment

    private var topSegment: some View {
        HStack(spacing: 0) {
            segmentTab(title: "QR Okut",   icon: "qrcode.viewfinder", tab: .scan)
            segmentTab(title: "QR Göster", icon: "qrcode",            tab: .show)
        }
        .padding(4)
        .background(Color(.systemGray5))
        .cornerRadius(14)
    }

    private func segmentTab(title: String, icon: String, tab: QRTab) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedTab = tab
                if tab == .scan { requestCameraIfNeeded() }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                Text(title).font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(selectedTab == tab ? .white : Color(.systemGray))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedTab == tab ? Color(.systemGray6) : Color.clear)
            .cornerRadius(11)
        }
    }

    // MARK: - QR Göster

    private var showContent: some View {
        VStack(spacing: 28) {
            if let room = viewModel.currentRoom {
                // QR kod — beyaz arka plansız, sadece QR görseli
                VStack(spacing: 20) {
                    Group {
                        if let qr = viewModel.qrCodeImage {
                            Image(uiImage: qr)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 220, height: 220)
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(20)
                                .transition(.opacity)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGray5))
                                    .frame(width: 252, height: 252)
                                ProgressView().tint(MenuLoTheme.Colors.primary).scaleEffect(1.4)
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.25), value: viewModel.qrCodeImage != nil)

                    // Oda kodu
                    VStack(spacing: 6) {
                        Text("Oda Kodu")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.systemGray))
                        Text("#\(room.pinCode)")
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .foregroundColor(MenuLoTheme.Colors.primary)
                            .tracking(8)
                    }

                    // Lobiye git butonu
                    Button {
                        showActiveRoom = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "door.right.hand.open")
                            Text("Lobiye Gir")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MenuLoTheme.Colors.primary)
                        .cornerRadius(14)
                        .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
                    }
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }
            } else {
                // Aktif oda yok — koyu, kart yok
                VStack(spacing: 24) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 64))
                        .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.3))
                        .padding(.top, 20)

                    VStack(spacing: 8) {
                        Text("Aktif oda yok")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                        Text("Oda oluştur ve arkadaşlarını davet et")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray))
                            .multilineTextAlignment(.center)
                    }

                    if viewModel.isLoading {
                        ProgressView().tint(MenuLoTheme.Colors.primary)
                    } else {
                        Button {
                            Task {
                                await viewModel.createRoom()
                                if viewModel.currentRoom != nil {
                                    showCreatedRoom = true
                                }
                            }
                        } label: {
                            Text("Oda Oluştur")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(MenuLoTheme.Colors.primary)
                                .cornerRadius(14)
                                .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    }

                    if let err = viewModel.errorMessage, !err.lowercased().contains("kategori") {
                        Text(err)
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MenuLoTheme.Spacing.xl)
                    }
                }
            }
        }
    }

    // MARK: - QR Okut

    private var scanContent: some View {
        VStack(spacing: 20) {
            // Kamera — direkt, beyaz kart yok
            ZStack {
                QRScannerRepresentable(
                    onCodeDetected: { rawCode in
                        let upper = rawCode.uppercased()
                        guard upper.count == 6,
                              upper.allSatisfy({ ($0 >= "A" && $0 <= "Z") || ($0 >= "0" && $0 <= "9") }) else {
                            shouldResetScanner = true
                            return
                        }
                        Task {
                            await viewModel.joinRoom(pinCode: upper)
                            if viewModel.currentRoom != nil { showActiveRoom = true }
                        }
                    },
                    shouldReset: $shouldResetScanner
                )

                // Tarama çizgisi
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                MenuLoTheme.Colors.primary.opacity(0),
                                MenuLoTheme.Colors.primary.opacity(0.85),
                                MenuLoTheme.Colors.primary.opacity(0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(y: -100 + (200 * scanProgress))
                    .onAppear {
                        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: true)) {
                            scanProgress = 1.0
                        }
                    }

                // Köşe çerçeveleri — basit L-şekil
                GeometryReader { geo in
                    let pad: CGFloat = 20
                    let len: CGFloat = 26
                    let t: CGFloat   = 3
                    let c            = Color.white.opacity(0.9)

                    ZStack {
                        // Sol üst
                        lCorner(x: pad, y: pad, len: len, t: t, color: c)
                        // Sağ üst
                        lCorner(x: geo.size.width - pad - len, y: pad, len: len, t: t, color: c, flipH: true)
                        // Sol alt
                        lCorner(x: pad, y: geo.size.height - pad - len, len: len, t: t, color: c, flipV: true)
                        // Sağ alt
                        lCorner(x: geo.size.width - pad - len, y: geo.size.height - pad - len, len: len, t: t, color: c, flipH: true, flipV: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 270)
            .cornerRadius(20)
            .clipped()
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            // Ayırıcı
            HStack(spacing: 12) {
                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
                Text("veya").font(.caption).foregroundColor(Color(.systemGray2))
                Rectangle().fill(Color(.systemGray4)).frame(height: 1)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.xl)

            // PIN girişi
            VStack(spacing: 12) {
                ZStack(alignment: .leading) {
                    if pinInput.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.systemGray3))
                            Text("Oda kodu gir  (A3F9C2)")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundColor(Color(.systemGray3))
                        }
                        .padding(.horizontal, 16)
                    }

                    HStack(spacing: 10) {
                        if pinInput.isEmpty {
                            Color.clear
                                .frame(width: 14 + 10, height: 14)
                        } else {
                            Image(systemName: "key.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.systemGray2))
                        }

                        TextField("", text: $pinInput)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .font(.system(size: 16, weight: .semibold, design: .monospaced))
                            .foregroundColor(MenuLoTheme.Colors.textPrimary)
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 50)
                .background(Color(.systemGray5))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            pinInput.isEmpty ? Color(.systemGray4) : MenuLoTheme.Colors.primary.opacity(0.7),
                            lineWidth: 1.5
                        )
                )
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

                if !pinInput.isEmpty {
                    Button {
                        Task {
                            await viewModel.joinRoom(pinCode: pinInput.uppercased())
                            if viewModel.currentRoom != nil { showActiveRoom = true }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isLoading {
                                ProgressView().tint(.white).scaleEffect(0.85)
                            } else {
                                Image(systemName: "arrow.right.circle.fill").font(.title3)
                                Text("Odaya Katıl").font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(MenuLoTheme.Colors.primary)
                        .cornerRadius(14)
                        .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 10, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, MenuLoTheme.Spacing.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if let err = viewModel.errorMessage, !err.lowercased().contains("kategori") {
                    Text(err)
                        .font(MenuLoTheme.Fonts.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                }
            }
            .animation(.spring(response: 0.28), value: pinInput.isEmpty)
        }
        .onAppear { requestCameraIfNeeded() }
    }

    // MARK: - L Köşe Çizici

    private func lCorner(
        x: CGFloat, y: CGFloat,
        len: CGFloat, t: CGFloat,
        color: Color,
        flipH: Bool = false, flipV: Bool = false
    ) -> some View {
        ZStack(alignment: .topLeading) {
            // Yatay çizgi
            Rectangle().fill(color).frame(width: len, height: t)
            // Dikey çizgi
            Rectangle().fill(color).frame(width: t, height: len)
        }
        .scaleEffect(x: flipH ? -1 : 1, y: flipV ? -1 : 1, anchor: .topLeading)
        .frame(width: len, height: len, alignment: .topLeading)
        .position(x: x + len / 2, y: y + len / 2)
    }

    // MARK: - Deep Link — Oda Katılımı

    private func handlePendingRoomDeepLink() {
        guard case .room(let pinCode) = deepLinkRouter.pending else { return }
        deepLinkRouter.pending = nil
        selectedTab = .scan
        pinInput = pinCode
        Task {
            await viewModel.joinRoom(pinCode: pinCode)
            if viewModel.currentRoom != nil { showActiveRoom = true }
        }
    }

    // MARK: - Kamera İzni

    private func requestCameraIfNeeded() {
        switch cameraPermission {
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                await MainActor.run {
                    cameraPermission = granted ? .authorized : .denied
                }
            }
        case .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        default: break
        }
    }
}

// MARK: - Oluşturulan Oda Ekranı

struct CreatedRoomView: View {
    let room: Room
    let onGoToLobby: () -> Void

    @EnvironmentObject private var viewModel: RoomViewModel
    @State private var isCopied = false

    var body: some View {
        NavigationStack {
            ZStack {
                MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: MenuLoTheme.Spacing.xl) {

                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(MenuLoTheme.Colors.primary.opacity(0.12))
                                    .frame(width: 96, height: 96)
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(MenuLoTheme.Colors.primary)
                            }
                            .padding(.top, MenuLoTheme.Spacing.xl)

                            Text("Oda Oluşturuldu!")
                                .font(MenuLoTheme.Fonts.largeTitle)
                                .foregroundColor(MenuLoTheme.Colors.textPrimary)

                            Text("Arkadaşlarını davet etmek için\nQR kodu paylaş veya kodu göster")
                                .font(MenuLoTheme.Fonts.body)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        Group {
                            if let qr = viewModel.qrCodeImage {
                                Image(uiImage: qr)
                                    .interpolation(.none).resizable().scaledToFit()
                                    .frame(width: 230, height: 230)
                                    .padding(MenuLoTheme.Spacing.lg)
                                    .background(Color.white)
                                    .cornerRadius(MenuLoTheme.CornerRadius.large)
                                    .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 4)
                                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                        .fill(Color.white).frame(width: 230, height: 230)
                                        .shadow(color: .black.opacity(0.08), radius: 14)
                                    ProgressView().scaleEffect(1.4).tint(MenuLoTheme.Colors.primary)
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.qrCodeImage != nil)

                        VStack(spacing: MenuLoTheme.Spacing.sm) {
                            Text("Oda Kodu")
                                .font(MenuLoTheme.Fonts.caption)
                                .foregroundColor(MenuLoTheme.Colors.textSecondary)

                            Button {
                                UIPasteboard.general.string = room.pinCode
                                withAnimation(.spring(response: 0.25)) { isCopied = true }
                                Task {
                                    try? await Task.sleep(for: .seconds(2))
                                    withAnimation { isCopied = false }
                                }
                            } label: {
                                HStack(spacing: MenuLoTheme.Spacing.md) {
                                    Text("#\(room.pinCode)")
                                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                                        .foregroundColor(MenuLoTheme.Colors.primary)
                                        .tracking(6)
                                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                        .font(.title2)
                                        .foregroundColor(isCopied ? .green : MenuLoTheme.Colors.textSecondary)
                                        .animation(.spring(response: 0.3), value: isCopied)
                                }
                                .padding(.horizontal, MenuLoTheme.Spacing.xl)
                                .padding(.vertical, MenuLoTheme.Spacing.md)
                                .background(MenuLoTheme.Colors.primary.opacity(0.08))
                                .cornerRadius(MenuLoTheme.CornerRadius.large)
                            }
                            .buttonStyle(.plain)

                            Text(isCopied ? "Kopyalandı!" : "Koda dokun ve kopyala")
                                .font(MenuLoTheme.Fonts.caption)
                                .foregroundColor(isCopied ? .green : MenuLoTheme.Colors.textSecondary)
                                .animation(.easeInOut(duration: 0.2), value: isCopied)
                        }

                        ShareLink(
                            item: "MenuLo'da bir karar odası kurdum! Katılmak için: menulo://room/\(room.pinCode) — veya uygulamada kod: #\(room.pinCode)",
                            subject: Text("Karar Odana Davet"),
                            message: Text("MenuLo uygulamasından katıl — menulo://room/\(room.pinCode)")
                        ) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Arkadaşlarınla Paylaş")
                            }
                            .font(MenuLoTheme.Fonts.button).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(MenuLoTheme.Spacing.md)
                            .background(MenuLoTheme.Colors.primary)
                            .cornerRadius(MenuLoTheme.CornerRadius.large)
                            .shadow(color: MenuLoTheme.Colors.primary.opacity(0.35), radius: 8)
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)

                        Button(action: onGoToLobby) {
                            Text("Lobiye Gir")
                                .font(MenuLoTheme.Fonts.button)
                                .foregroundColor(MenuLoTheme.Colors.primary)
                                .frame(maxWidth: .infinity).padding(MenuLoTheme.Spacing.md)
                                .background(MenuLoTheme.Colors.primary.opacity(0.08))
                                .cornerRadius(MenuLoTheme.CornerRadius.large)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                                        .strokeBorder(MenuLoTheme.Colors.primary.opacity(0.3), lineWidth: 1.5)
                                )
                        }
                        .padding(.horizontal, MenuLoTheme.Spacing.lg)
                        .padding(.bottom, MenuLoTheme.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Odana Davet Et")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Aktif Oda (Lobi)

struct ActiveRoomView: View {
    let room: Room
    let onLeave: () -> Void

    @EnvironmentObject private var viewModel: RoomViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToVoting = false

    private let foodCategories: [(name: String, emoji: String)] = [
        ("Pizza", "🍕"),  ("Hamburger", "🍔"), ("Salata", "🥗"),
        ("Sushi", "🍣"),  ("Steak", "🥩"),     ("Döner", "🌯"),
        ("Makarna", "🍝"),("Çorba", "🍲"),     ("Tatlı", "🍰"),
        ("Deniz Ürünleri", "🦐"), ("Ramen", "🍜"), ("Vegan", "🌱"),
        ("Kahve", "☕"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: MenuLoTheme.Spacing.xl) {
                    inviteSection
                    categorySection
                    participantSection
                    actionButtons
                }
                .padding(.top, MenuLoTheme.Spacing.lg)
                .padding(.bottom, MenuLoTheme.Spacing.xl)
            }
            .background(MenuLoTheme.Colors.backgroundLight.ignoresSafeArea())
            .navigationTitle(room.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }
            }
            .navigationDestination(isPresented: $navigateToVoting) {
                RoomVotingView(room: room, onLeave: { onLeave(); dismiss() })
                    .environmentObject(viewModel)
            }
            .onChange(of: viewModel.isVotingStarted) { started in
                if started { navigateToVoting = true }
            }
        }
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            HStack(spacing: 6) {
                Image(systemName: "person.badge.plus")
                    .foregroundColor(MenuLoTheme.Colors.primary).font(.footnote)
                Text("Arkadaşlarını Davet Et")
                    .font(MenuLoTheme.Fonts.subtitle)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            HStack(spacing: MenuLoTheme.Spacing.lg) {
                if let qr = viewModel.qrCodeImage {
                    Image(uiImage: qr)
                        .interpolation(.none).resizable().scaledToFit()
                        .frame(width: 88, height: 88).padding(8)
                        .background(Color.white)
                        .cornerRadius(MenuLoTheme.CornerRadius.medium)
                        .shadow(color: .black.opacity(0.07), radius: 6)
                        .transition(.opacity)
                } else {
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.medium)
                        .fill(Color.white).frame(width: 88, height: 88)
                        .overlay(ProgressView().tint(MenuLoTheme.Colors.primary))
                        .shadow(color: .black.opacity(0.07), radius: 6)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Oda Kodu")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    Text("#\(room.pinCode)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(MenuLoTheme.Colors.primary).tracking(4)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isSocketConnected ? MenuLoTheme.Colors.success : .gray)
                            .frame(width: 7, height: 7)
                        Text(viewModel.isSocketConnected ? "Canlı" : "Bağlanıyor...")
                            .font(MenuLoTheme.Fonts.caption)
                            .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    }
                }
                Spacer()
            }
            .padding(MenuLoTheme.Spacing.lg)
            .background(MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            .animation(.easeInOut(duration: 0.25), value: viewModel.qrCodeImage != nil)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: MenuLoTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife")
                        .foregroundColor(MenuLoTheme.Colors.primary).font(.footnote)
                    Text("Ne Yemek İstersin?")
                        .font(MenuLoTheme.Fonts.subtitle)
                        .foregroundColor(MenuLoTheme.Colors.textPrimary)
                }
                Text("Seçimler grup eşleşmesinde kullanılır · En az 1 seç")
                    .font(MenuLoTheme.Fonts.caption)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: MenuLoTheme.Spacing.sm
            ) {
                ForEach(foodCategories, id: \.name) { cat in
                    FoodCategoryChip(
                        name: cat.name, emoji: cat.emoji,
                        isSelected: viewModel.selectedCategories.contains(cat.name)
                    ) {
                        withAnimation(.spring(response: 0.2)) {
                            if viewModel.selectedCategories.contains(cat.name) {
                                viewModel.selectedCategories.remove(cat.name)
                            } else {
                                viewModel.selectedCategories.insert(cat.name)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
        }
    }

    private var participantSection: some View {
        HStack(spacing: MenuLoTheme.Spacing.sm) {
            Image(systemName: "person.2.fill").foregroundColor(MenuLoTheme.Colors.primary)
            Text("\(max(viewModel.participantIds.count, 1)) katılımcı")
                .font(MenuLoTheme.Fonts.body).foregroundColor(MenuLoTheme.Colors.textPrimary)
            Spacer()
            if !viewModel.isSocketConnected {
                Label("Bağlanıyor", systemImage: "wifi.exclamationmark")
                    .font(MenuLoTheme.Fonts.caption).foregroundColor(.orange)
            }
        }
        .padding(MenuLoTheme.Spacing.lg)
        .background(MenuLoTheme.Colors.cardBackground)
        .cornerRadius(MenuLoTheme.CornerRadius.large)
        .shadow(color: .black.opacity(0.04), radius: 4)
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
    }

    private var actionButtons: some View {
        VStack(spacing: MenuLoTheme.Spacing.md) {
            Button {
                viewModel.submitCategories()
                viewModel.startVoting()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "hand.thumbsup.circle.fill").font(.title3)
                    Text("Oylamaya Başla")
                }
                .font(MenuLoTheme.Fonts.button).foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(MenuLoTheme.Spacing.md)
                .background(viewModel.selectedCategories.isEmpty
                             ? MenuLoTheme.Colors.primary.opacity(0.45)
                             : MenuLoTheme.Colors.primary)
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .shadow(color: viewModel.selectedCategories.isEmpty
                         ? .clear : MenuLoTheme.Colors.primary.opacity(0.35), radius: 8)
            }
            .disabled(viewModel.selectedCategories.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedCategories.isEmpty)

            if viewModel.selectedCategories.isEmpty {
                Text("Oylamaya başlamak için en az 1 kategori seç")
                    .font(.caption2).foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .transition(.opacity)
            }

            Button { onLeave(); dismiss() } label: {
                Text("Odadan Ayrıl")
                    .font(MenuLoTheme.Fonts.button).foregroundColor(.red)
                    .frame(maxWidth: .infinity).padding(MenuLoTheme.Spacing.md)
                    .background(Color.red.opacity(0.08))
                    .cornerRadius(MenuLoTheme.CornerRadius.large)
            }
        }
        .padding(.horizontal, MenuLoTheme.Spacing.lg)
    }
}

// MARK: - Kategori Chip

private struct FoodCategoryChip: View {
    let name: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 26))
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : MenuLoTheme.Colors.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MenuLoTheme.Spacing.sm)
            .background(isSelected ? MenuLoTheme.Colors.primary : MenuLoTheme.Colors.cardBackground)
            .cornerRadius(MenuLoTheme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                    .strokeBorder(isSelected ? Color.clear : MenuLoTheme.Colors.divider, lineWidth: 1.5)
            )
            .shadow(color: isSelected ? MenuLoTheme.Colors.primary.opacity(0.3) : .clear, radius: 6)
        }
    }
}

// MARK: - Preview

#Preview {
    RoomListView()
        .environmentObject(RoomViewModel())
        .environmentObject(DeepLinkRouter())
}
