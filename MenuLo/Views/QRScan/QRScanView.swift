import SwiftUI
import AVFoundation

// MARK: - QRScanView
// Tab 2 ana görünümü: "QR Okut" (kamera) ve "QR Göster" (oda kodu).
// Paylaşılan RoomViewModel EnvironmentObject olarak MainTabView'dan gelir.

struct QRScanView: View {

    @EnvironmentObject private var viewModel: RoomViewModel
    @State private var selectedTab          = 0
    @State private var navigateToRoom       = false
    @State private var joinTriggeredByQR    = false  // sadece QR taramasından gelen join'leri yakala

    // Tarama animasyonu
    @State private var scanProgress: CGFloat = 0

    var body: some View {
        ZStack {
            MenuLoTheme.Colors.backgroundLight.ignoresSafeArea()

            VStack(spacing: 0) {

                // Segmented tab seçici
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
        // QR taraması sonrası odaya katılım başarılıysa ActiveRoomView'a yönlendir
        .navigationDestination(isPresented: $navigateToRoom) {
            if let room = viewModel.currentRoom {
                ActiveRoomView(
                    room: room,
                    participantIds: viewModel.participantIds,
                    onLeave: { viewModel.leaveCurrentRoom() }
                )
            }
        }
        // joinRoom tamamlandığında ve QR akışından geliyorsa navigate et
        .onChange(of: viewModel.currentRoom?.roomId) { roomId in
            if roomId != nil && joinTriggeredByQR {
                joinTriggeredByQR = false
                navigateToRoom    = true
            }
        }
        // Hata alert'i
        .alert("Hata", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("Tamam", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - QR Okut Sekmesi

    private var scanTab: some View {
        VStack(spacing: 0) {
            ZStack {
                // AVFoundation kamera önizlemesi — UIViewControllerRepresentable
                QRScannerRepresentable { code in
                    handleScannedCode(code)
                }
                .cornerRadius(MenuLoTheme.CornerRadius.large)
                .clipped()

                // Tarama çerçevesi + animasyonu
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

                // Yükleniyor örtüsü (join REST çağrısı sırasında)
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

    // MARK: - QR Göster Sekmesi

    private var showTab: some View {
        VStack(spacing: MenuLoTheme.Spacing.xl) {
            Spacer()

            if let room = viewModel.currentRoom {
                // Aktif oda var — QR ve PIN göster
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
                            .interpolation(.none)  // piksel bozulmasını önler
                            .resizable()
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                    } else {
                        ProgressView()
                    }

                    // Marka logosu QR'ın ortasında
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    Image(systemName: "fork.knife.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .foregroundColor(MenuLoTheme.Colors.primary)
                }

                // PIN metni
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

                // Odayı Aç butonu
                PrimaryButton(title: "Odayı Aç") {
                    navigateToRoom = true
                }
                .padding(.horizontal, MenuLoTheme.Spacing.lg)

            } else {
                // Aktif oda yok
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

        // Haptic feedback — başarılı okuma hissi
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        joinTriggeredByQR = true
        Task { await viewModel.joinRoom(pinCode: code.uppercased()) }
    }
}

// MARK: - QR Scanner (UIViewControllerRepresentable)
// AVFoundation kamerasını SwiftUI'a sarar.
// Bellek güvenliği: delegate ayrı bir Coordinator sınıfında, VC'ye weak ref ile.

struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeDetected: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let vc = QRScannerController()
        vc.onCodeDetected = onCodeDetected
        return vc
    }

    func updateUIViewController(_ vc: QRScannerController, context: Context) {
        vc.onCodeDetected = onCodeDetected
    }
}

// MARK: - QRScannerController

final class QRScannerController: UIViewController {

    var onCodeDetected: ((String) -> Void)?

    private let session      = AVCaptureSession()
    // Kamera ayarları ve startRunning/stopRunning bu queue üzerinden çalışır.
    // Ana thread'i bloke etmez; bellek sızıntısı riskini azaltır.
    private let sessionQueue = DispatchQueue(label: "com.menulo.camera.session", qos: .userInitiated)
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var coordinator:  QRMetadataCoordinator?
    private var isConfigured = false

    // MARK: - Lifecycle

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
        // sessionQueue.sync ile deinit tamamlanmadan session durdurulur
        sessionQueue.sync { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - Kamera İzni ve Konfigürasyon

    private func requestAndConfigure() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.configureSession()
                } else {
                    DispatchQueue.main.async { self?.showPermissionMessage() }
                }
            }
        default:
            showPermissionMessage()
        }
    }

    private func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.session.beginConfiguration()

            guard let device = AVCaptureDevice.default(for: .video) else {
                self.session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    return
                }
                self.session.addInput(input)
            } catch {
                self.session.commitConfiguration()
                return
            }

            let output = AVCaptureMetadataOutput()
            guard self.session.canAddOutput(output) else {
                self.session.commitConfiguration()
                return
            }
            self.session.addOutput(output)

            // Delegate ayrı Coordinator sınıfında: retain cycle riski yok.
            // QRScannerController → (strong) coordinator
            // coordinator → (weak) session (sadece stopRunning için)
            // AVCaptureOutput → (strong) coordinator  (VC'ye geri referans yok)
            let coord = QRMetadataCoordinator(sessionQueue: self.sessionQueue)
            coord.onCodeDetected = { [weak self] code in
                self?.onCodeDetected?(code)
            }
            output.setMetadataObjectsDelegate(coord, queue: .main)
            output.metadataObjectTypes = [.qr]
            self.coordinator = coord

            self.session.commitConfiguration()
            self.isConfigured = true

            // Preview layer ana thread'de oluşturulmalı
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

    /// Kamera izni verilmediğinde kullanıcıya mesaj göster.
    private func showPermissionMessage() {
        let label = UILabel()
        label.text          = "Kamera izni gerekiyor.\nAyarlar > Gizlilik > Kamera'dan izin verin."
        label.textColor     = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font          = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    // MARK: - Taramayı Yeniden Başlat

    func resetScanner() {
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }
}

// MARK: - QRMetadataCoordinator
// AVCaptureMetadataOutputObjectsDelegate'i QRScannerController'dan izole eder.
// Bu sayede AVCaptureOutput → Coordinator → weak closure zinciriyle retain cycle oluşmaz.

final class QRMetadataCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    var onCodeDetected: ((String) -> Void)?
    private let sessionQueue: DispatchQueue
    private var hasDetected = false  // çoklu callback'i önler

    init(sessionQueue: DispatchQueue) {
        self.sessionQueue = sessionQueue
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        // Kamera 60fps çalışabilir — sadece ilk geçerli okumayı işle
        guard !hasDetected,
              let obj  = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr,
              let code = obj.stringValue else { return }

        hasDetected = true

        // Session'ı arka planda durdur, UI callback'ini ana thread'de tetikle
        sessionQueue.async { [weak output] in
            output?.metadataObjectsDelegate = nil  // hızlı durdur
        }

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
    let position: Int  // 0=TL  1=TR  2=BL  3=BR
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
