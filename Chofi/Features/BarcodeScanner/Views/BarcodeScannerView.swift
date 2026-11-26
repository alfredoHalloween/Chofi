//
//  BarcodeScannerView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import SwiftUI
import UIKit

/// Pantalla que lee un código de barras con la cámara y escribe su valor en `scannedCode`.
/// Quien la presenta decide cómo hacerlo (`.sheet` o `.fullScreenCover`); la pantalla se cierra sola.
struct BarcodeScannerView: View {
    @Binding var scannedCode: String?

    @StateObject private var viewModel: BarcodeScannerViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let hasTorch = BarcodeCaptureViewController.deviceHasTorch

    @MainActor
    init(scannedCode: Binding<String?>) {
        _scannedCode = scannedCode
        _viewModel = StateObject(wrappedValue: BarcodeScannerViewModel())
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch viewModel.state {
            case .checkingPermission:
                ProgressView()
                    .tint(.white)
            case .scanning:
                scanner
            case .permissionDenied:
                message(
                    systemImage: "camera.fill",
                    title: "Sin acceso a la cámara",
                    text: "Para leer códigos de barras, permite que Chofi use la cámara en Ajustes.",
                    showsSettingsButton: true
                )
            case .cameraUnavailable:
                message(
                    systemImage: "video.slash.fill",
                    title: "Cámara no disponible",
                    text: "Este dispositivo no tiene una cámara que se pueda usar para leer códigos.",
                    showsSettingsButton: false
                )
            }
        }
        .task {
            await viewModel.start()
        }
        .onChange(of: viewModel.scannedCode) { code in
            guard let code else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            scannedCode = code
            dismiss()
        }
    }

    // MARK: - Escaneo

    private var scanner: some View {
        ZStack {
            CameraPreviewView(isTorchOn: viewModel.isTorchOn) { code in
                viewModel.handle(code: code)
            }
            .ignoresSafeArea()

            GuideOverlay()
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Button("Cancelar", action: close)
                        .buttonStyle(.bordered)

                    Spacer()

                    if hasTorch {
                        Button {
                            viewModel.isTorchOn.toggle()
                        } label: {
                            Image(systemName: viewModel.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(viewModel.isTorchOn ? "Apagar linterna" : "Encender linterna")
                    }
                }
                .tint(.white)
                .padding()

                Spacer()

                Text("Coloca el código de barras dentro del recuadro")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }

    // MARK: - Mensajes

    private func message(
        systemImage: String,
        title: String,
        text: String,
        showsSettingsButton: Bool
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
            Text(title)
                .font(.title2.bold())
            Text(text)
                .multilineTextAlignment(.center)

            if showsSettingsButton {
                Button("Abrir Ajustes") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Cerrar", action: close)
                .buttonStyle(.bordered)
        }
        .foregroundStyle(.white)
        .tint(.white)
        .padding(32)
    }

    /// Cierra sin lectura: el binding queda en `nil`.
    private func close() {
        scannedCode = nil
        dismiss()
    }
}

/// Oscurece la imagen fuera del recuadro guía y lo marca con un borde.
/// Usa el mismo rectángulo que `BarcodeCaptureViewController` para limitar la lectura.
private struct GuideOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            let guide = BarcodeCaptureViewController.guideRect(
                in: CGRect(origin: .zero, size: proxy.size)
            )

            ZStack {
                Color.black.opacity(0.5)
                    .mask {
                        ZStack {
                            Rectangle()
                            RoundedRectangle(cornerRadius: 12)
                                .frame(width: guide.width, height: guide.height)
                                .position(x: guide.midX, y: guide.midY)
                                .blendMode(.destinationOut)
                        }
                        .compositingGroup()
                    }

                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white, lineWidth: 3)
                    .frame(width: guide.width, height: guide.height)
                    .position(x: guide.midX, y: guide.midY)
            }
        }
    }
}

// MARK: - Preview

/// Host de prueba: correr en un iPhone real para usar la cámara.
private struct BarcodeScannerPreviewHost: View {
    @State private var scannedCode: String?
    @State private var isScanning = false

    var body: some View {
        VStack(spacing: 24) {
            Text(scannedCode ?? "Sin lectura")
                .font(.title2.monospacedDigit())

            Button("Escanear") {
                isScanning = true
            }
            .buttonStyle(.borderedProminent)
        }
        .fullScreenCover(isPresented: $isScanning) {
            BarcodeScannerView(scannedCode: $scannedCode)
        }
    }
}

#Preview {
    BarcodeScannerPreviewHost()
}
