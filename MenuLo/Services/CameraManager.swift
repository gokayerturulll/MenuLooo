//
//  CameraManager.swift
//  MenuLo
//
//  MenuLo/Services/CameraManager.swift
//
//  QR Kod okuma işlemleri için cihaz kamerasını (AVFoundation) yöneten servis.
//

import SwiftUI
import AVFoundation

class CameraManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var permissionGranted = false
    @Published var scannedCode: String?
    
    let captureSession = AVCaptureSession()
    private var isSessionSetup = false
    
    func requestPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.permissionGranted = true }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.permissionGranted = granted }
            }
        default:
            DispatchQueue.main.async { self.permissionGranted = false }
        }
    }
    
    func setupCamera() {
        guard permissionGranted, !isSessionSetup else { return }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Kamera input hatası: \(error)")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        isSessionSetup = true
    }
    
    func startSession() {
        if !captureSession.isRunning && isSessionSetup {
            DispatchQueue.global(qos: .background).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            DispatchQueue.main.async {
                self.scannedCode = stringValue
                self.stopSession()
            }
        }
    }
}

// MARK: - SwiftUI Preview View for Camera
struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        // Bu layer, view boyutu değiştikçe kendi boyutunu güncellemeli
        view.layer.addSublayer(previewLayer)
        
        // Ekran boyutlarına dinamik tepki vermek için
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
