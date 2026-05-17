import SwiftUI
import AVFoundation

// MARK: - QRScanView

struct QRScanView: View {

    @EnvironmentObject private var viewModel: RoomViewModel
    @State private var selectedTab          = 0
    @State private var navigateToRoom       = false
    @State private var joinTriggeredByQR    = false
    @State private var scanFailedByQR       = false   // tracks QR-triggered join failures
    @State private var shouldResetScanner   = false   // rising-edge signal to QRScannerRepresentable
    @State private var scanProgress: CGFloat = 0
    @State private var cameraPermission     = AVCaptureDevice.authorizationStatus(for: .video)

    var body: some View {
        ZStack {
            MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("İşlem", selection: $selectedTab) {
                    Text("QR Okut").tag(0)
                    Text("QR Göster").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MenuLoTheme.Spacing.lg)
                .padding(.top, MenuLoTheme.Spacing.md)
                .padding(.bottom, MenuLoTheme.Spacing.lg)

                if selectedTab == 0 {
                    scanTab
                } else {
                    showTab
                }
            }
        }
        .navigationTitle("Grup Karar Odası")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToRoom) {
            if let room = viewModel.currentRoom {
                RoomVotingView(room: room, onLeave: { viewModel.leaveCurrentRoom() })
            }
        }
        .onChange(of: viewModel.currentRoom?.roomId) { roomId in
            if roomId != nil && joinTriggeredByQR {
                joinTriggeredByQR = false
                navigateToRoom    = true
            }
        }
        // When a QR-triggered join fails, schedule scanner reset
        .onChange(of: viewModel.isLoading) { loading in
            if !loading, viewModel.errorMessage != nil, joinTriggeredByQR {
                joinTriggeredByQR = false
                scanFailedByQR    = true
            }
        }
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { dismissed in
                if !dismissed {
                    viewModel.errorMessage = nil
                    if scanFailedByQR {
                        scanFailedByQR      = false
                        shouldResetScanner  = true
                    }
                }
            }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - QR Okut Sekmesi

    @ViewBuilder
    private var scanTab: some View {
        switch cameraPermission {
        case .authorized:
            authorizedCameraView
        case .notDetermined:
            permissionRequestView
        default:
            permissionDeniedView
        }
    }

    private var authorizedCameraView: some View {
        VStack(spacing: 0) {
            ZStack {
                QRScannerRepresentable(
                    onCodeDetected: handleScannedCode,
                    shouldReset: $shouldResetScanner
                )
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .clipped()

                ZStack {
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 260, height: 260)

                    QRCorners(size: 260)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MenuLoTheme.Colors.primary.opacity(0),
                                    MenuLoTheme.Colors.primary,
                                    MenuLoTheme.Colors.primary.opacity(0),
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

                if viewModel.isLoading {
                    Color.black.opacity(0.5)
                        .cornerRadius(MenuLoTheme.CornerRadius.large)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
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

    private var permissionRequestView: some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            Spacer()
            Image(systemName: "camera.circle")
                .font(.system(size: 72))
                .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.6))

            VStack(spacing: MenuLoTheme.Spacing.sm) {
                Text("Kamera İzni Gerekiyor")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Text("QR kodu okuyabilmek için kamera erişimine ihtiyacımız var.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MenuLoTheme.Spacing.xl)
            }

            PrimaryButton(title: "Kamera İznini Ver") {
                Task {
                    let granted = await AVCaptureDevice.requestAccess(for: .video)
                    cameraPermission = granted ? .authorized : .denied
                }
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            Spacer()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            Spacer()
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 72))
                .foregroundColor(.red.opacity(0.6))

            VStack(spacing: MenuLoTheme.Spacing.sm) {
                Text("Kamera İzni Reddedildi")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)
                Text("QR tarayıcı için kamera iznini Ayarlar > Gizlilik > Kamera bölümünden açabilirsin.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MenuLoTheme.Spacing.xl)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "gear")
                    Text("Ayarlara Git")
                }
                .font(MenuLoTheme.Fonts.button)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(MenuLoTheme.Spacing.md)
                .background(MenuLoTheme.Colors.primary)
                .cornerRadius(MenuLoTheme.CornerRadius.large)
            }
            .padding(.horizontal, MenuLoTheme.Spacing.lg)
            Spacer()
        }
        // Refresh status when user returns from Settings
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            cameraPermission = AVCaptureDevice.authorizationStatus(for: .video)
        }
    }

    // MARK: - QR Göster Sekmesi

    private var showTab: some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            Spacer()

            if let room = viewModel.currentRoom {
                Text(room.name)
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                ZStack {
                    RoundedRectangle(cornerRadius: MenuLoTheme.CornerRadius.large)
                        .fill(Color.white)
                        .frame(width: 280, height: 280)
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)

                    if let qr = viewModel.qrCodeImage {
                        Image(uiImage: qr)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                    } else {
                        ProgressView()
                    }

                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }

                VStack(spacing: 4) {
                    Text("PIN")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    Text(room.pinCode)
                        .font(.system(.title, design: .monospaced)).fontWeight(.bold)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                        .tracking(6)
                }

                Text("Arkadaşların bu kodu okutarak odana katılabilir")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MenuLoTheme.Spacing.xl)

                PrimaryButton(title: "Odayı Aç") {
                    navigateToRoom = true
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(MenuLoTheme.Colors.primary.opacity(0.25))

                Text("Aktif Oda Yok")
                    .font(MenuLoTheme.Fonts.title)
                    .foregroundColor(MenuLoTheme.Colors.textPrimary)

                Text("QR Okut sekmesinden bir odaya katıl veya Oda Listesinden yeni oda oluştur.")
                    .font(MenuLoTheme.Fonts.body)
                    .foregroundColor(MenuLoTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, MenuLoTheme.Spacing.xl)
            }

            Spacer()
        }
    }

    // MARK: - QR Kod İşleme

    private func handleScannedCode(_ code: String) {
        guard !viewModel.isLoading else { return }

        let upper = code.uppercased()

        // PIN doğrulama: tam 6 karakter, yalnızca A-Z ve 0-9
        guard upper.count == 6,
              upper.allSatisfy({ ($0 >= "A" && $0 <= "Z") || ($0 >= "0" && $0 <= "9") }) else {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
            shouldResetScanner = true
            return
        }

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        joinTriggeredByQR = true
        Task { await viewModel.joinRoom(pinCode: upper) }
    }
}

// MARK: - QRScannerRepresentable

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeDetected: (String) -> Void
    @Binding var shouldReset: Bool

    func makeUIViewController(context: Context) -> QRScannerController {
        let vc = QRScannerController()
        vc.onCodeDetected = onCodeDetected
        return vc
    }

    func updateUIViewController(_ vc: QRScannerController, context: Context) {
        vc.onCodeDetected = onCodeDetected
        if shouldReset {
            vc.resetScanner()
            // Lower the flag back on the next run-loop tick to avoid re-entry
            DispatchQueue.main.async { shouldReset = false }
        }
    }
}

// MARK: - QRScannerController

final class QRScannerController: UIViewController {

    var onCodeDetected: ((String) -> Void)?

    private let session      = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.menulo.camera.session", qos: .userInitiated)
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var coordinator:  QRMetadataCoordinator?
    private var isConfigured  = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        requestAndConfigure()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sessionQueue.async { [weak self] in
            guard self?.session.isRunning == true else { return }
            self?.session.stopRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    deinit {
        sessionQueue.sync { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - İzin & Konfigürasyon

    private func requestAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted { self?.configureSession() }
            }
        default:
            break
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()

            guard let device = AVCaptureDevice.default(for: .video),
                  let input  = try? AVCaptureDeviceInput(device: device),
                  self.session.canAddInput(input) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addOutput(output)

            let coord = QRMetadataCoordinator(sessionQueue: self.sessionQueue)
            coord.onCodeDetected = { [weak self] code in
                self?.onCodeDetected?(code)
            }
            output.setMetadataObjectsDelegate(coord, queue: .main)
            output.metadataObjectTypes = [.qr]
            self.coordinator = coord

            self.session.commitConfiguration()
            self.isConfigured = true

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.frame        = self.view.bounds
                layer.videoGravity = .resizeAspectFill
                self.view.layer.insertSublayer(layer, at: 0)
                self.previewLayer = layer
            }

            self.session.startRunning()
        }
    }

    // MARK: - Taramayı Sıfırla (API hatası veya geçersiz PIN sonrası)

    func resetScanner() {
        coordinator?.reset()
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
}

// MARK: - QRMetadataCoordinator

final class QRMetadataCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    var onCodeDetected: ((String) -> Void)?
    private let sessionQueue: DispatchQueue
    private var hasDetected = false

    init(sessionQueue: DispatchQueue) {
        self.sessionQueue = sessionQueue
    }

    func reset() {
        hasDetected = false
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard !hasDetected,
              let obj  = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr,
              let code = obj.stringValue else { return }

        hasDetected = true

        onCodeDetected?(code)
    }
}

// MARK: - QR Köşe Dekorasyon Bileşeni

private struct QRCorners: View {
    let size: CGFloat
    let cornerLength: CGFloat = 24
    let lineWidth: CGFloat    = 4

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
    let position: Int
    let length: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch position {
        case 0:
            p.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        case 1:
            p.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        case 2:
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY - length))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        case 3:
            p.move(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        default: break
        }
        return p
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QRScanView()
            .environmentObject(RoomViewModel())
    }
}
