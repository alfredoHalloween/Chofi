//
//  BarcodeScannerViewModel.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import AVFoundation

/// Abstrae el permiso y la disponibilidad de la cámara para poder probar los estados sin hardware.
protocol CameraAuthorizing {
    var status: AVAuthorizationStatus { get }
    var isCameraAvailable: Bool { get }
    func requestAccess() async -> Bool
}

/// Implementación real sobre `AVCaptureDevice`.
struct SystemCameraAuthorizer: CameraAuthorizing {
    var status: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    var isCameraAvailable: Bool {
        AVCaptureDevice.default(for: .video) != nil
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: .video)
    }
}

@MainActor
final class BarcodeScannerViewModel: ObservableObject {
    @Published private(set) var state: BarcodeScannerState = .checkingPermission
    @Published private(set) var scannedCode: String?
    @Published var isTorchOn = false

    private let camera: CameraAuthorizing

    init(camera: CameraAuthorizing = SystemCameraAuthorizer()) {
        self.camera = camera
    }

    /// Resuelve el estado inicial según la disponibilidad de la cámara y el permiso.
    func start() async {
        guard camera.isCameraAvailable else {
            state = .cameraUnavailable
            return
        }

        switch camera.status {
        case .authorized:
            state = .scanning
        case .notDetermined:
            state = await camera.requestAccess() ? .scanning : .permissionDenied
        case .denied, .restricted:
            state = .permissionDenied
        @unknown default:
            state = .permissionDenied
        }
    }

    /// Registra el primer código leído. Ignora valores vacíos y cualquier lectura posterior.
    func handle(code: String) {
        guard scannedCode == nil else { return }
        let value = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        scannedCode = value
    }
}
