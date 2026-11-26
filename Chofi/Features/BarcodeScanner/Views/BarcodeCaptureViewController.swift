//
//  BarcodeCaptureViewController.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import AVFoundation
import UIKit

/// Muestra la cámara y lee códigos EAN-13, EAN-8 y UPC-E dentro del recuadro guía.
final class BarcodeCaptureViewController: UIViewController {

    /// Se llama en el hilo principal con el primer código leído. Las lecturas posteriores se ignoran.
    var onCode: ((String) -> Void)?

    /// Tipos de código soportados.
    static let supportedTypes: [AVMetadataObject.ObjectType] = [.ean13, .ean8, .upce]

    /// Indica si la cámara trasera tiene linterna.
    static var deviceHasTorch: Bool {
        AVCaptureDevice.default(for: .video)?.hasTorch ?? false
    }

    /// Recuadro guía centrado. La vista SwiftUI dibuja el mismo rectángulo encima de la cámara.
    static func guideRect(in bounds: CGRect) -> CGRect {
        let width = min(bounds.width * 0.8, 320)
        let height = width * 0.5
        return CGRect(
            x: bounds.midX - width / 2,
            y: bounds.midY - height / 2,
            width: width,
            height: height
        )
    }

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.chofi.barcode-scanner.session")
    private let metadataOutput = AVCaptureMetadataOutput()
    private var device: AVCaptureDevice?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasDeliveredCode = false
    private var sessionStartObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer

        sessionStartObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionDidStartRunning,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.updateRectOfInterest()
        }

        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updatePreviewOrientation()
        updateRectOfInterest()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async { [session] in
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setTorch(false)
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    deinit {
        if let sessionStartObserver {
            NotificationCenter.default.removeObserver(sessionStartObserver)
        }
        // Respaldo por si `viewWillDisappear` no llega: la cámara no debe quedar encendida.
        sessionQueue.async { [session] in
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    /// Enciende o apaga la linterna. No hace nada si el dispositivo no tiene.
    func setTorch(_ isOn: Bool) {
        sessionQueue.async { [weak self] in
            guard let device = self?.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                // Si no se puede bloquear el dispositivo, la linterna conserva su estado.
            }
        }
    }

    // MARK: - Configuración

    /// Se ejecuta en `sessionQueue`.
    private func configureSession() {
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input = try? AVCaptureDeviceInput(device: device)
        else { return }

        session.beginConfiguration()
        guard session.canAddInput(input), session.canAddOutput(metadataOutput) else {
            session.commitConfiguration()
            return
        }
        session.addInput(input)
        session.addOutput(metadataOutput)

        metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
        metadataOutput.metadataObjectTypes = Self.supportedTypes.filter {
            metadataOutput.availableMetadataObjectTypes.contains($0)
        }
        session.commitConfiguration()

        self.device = device

        // Arranca en cuanto está configurada. No depende de que SwiftUI reenvíe `viewWillAppear`
        // al controlador, porque se inserta cuando la pantalla ya está visible.
        if !session.isRunning {
            session.startRunning()
        }
    }

    /// Limita la lectura al recuadro guía. Solo es exacto con la sesión corriendo y la capa con tamaño.
    private func updateRectOfInterest() {
        guard let previewLayer, !view.bounds.isEmpty else { return }
        let guide = Self.guideRect(in: view.bounds)
        let rect = previewLayer.metadataOutputRectConverted(fromLayerRect: guide)
        sessionQueue.async { [metadataOutput] in
            metadataOutput.rectOfInterest = rect
        }
    }

    /// Mantiene la imagen derecha cuando la interfaz gira.
    private func updatePreviewOrientation() {
        guard
            let connection = previewLayer?.connection,
            connection.isVideoOrientationSupported,
            let orientation = view.window?.windowScene?.interfaceOrientation
        else { return }

        switch orientation {
        case .landscapeLeft: connection.videoOrientation = .landscapeLeft
        case .landscapeRight: connection.videoOrientation = .landscapeRight
        case .portraitUpsideDown: connection.videoOrientation = .portraitUpsideDown
        default: connection.videoOrientation = .portrait
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension BarcodeCaptureViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard
            !hasDeliveredCode,
            let code = metadataObjects
                .compactMap({ $0 as? AVMetadataMachineReadableCodeObject })
                .first(where: { Self.supportedTypes.contains($0.type) })?
                .stringValue,
            !code.isEmpty
        else { return }

        hasDeliveredCode = true
        onCode?(code)
    }
}
