//
//  CameraManager.swift
//  MenuLo
//
//  MenuLo/Services/CameraManager.swift
//
//  QR Kod okuma işlemleri için cihaz kamerasını (AVFoundation) yöneten servis.
//

import Foundation
import AVFoundation

class CameraManager: NSObject, ObservableObject {
    // Kameraya erişim izninin durumunu tutar
    @Published var permissionGranted = false
    
    // Kamera video akışını yakalayan ana oturum nesnesi
    let captureSession = AVCaptureSession()
    
    /// Kamera için kullanıcıdan izin ister
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // İzin zaten verilmiş
            self.permissionGranted = true
        case .notDetermined:
            // Henüz izin sorulmamış, sor
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.permissionGranted = granted
                }
            }
        default:
            // İzin reddedilmiş veya kısıtlanmış
            self.permissionGranted = false
        }
    }
    
    /// QR okumak için kamerayı ve captureSession'ı ayarlar
    func setupCamera() {
        guard permissionGranted else { return }
        
        // Cihazın arka kamerasını bul
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            }
            
            // Metadata (QR kod) okuma ayarları burada eklenebilir.
            
        } catch {
            print("Kamera kurulum hatası: \(error.localizedDescription)")
        }
    }
}
