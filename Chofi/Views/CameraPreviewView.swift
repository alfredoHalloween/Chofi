//
//  CameraPreviewView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import SwiftUI

/// Puente SwiftUI hacia `BarcodeCaptureViewController`.
struct CameraPreviewView: UIViewControllerRepresentable {
    var isTorchOn: Bool
    var onCode: (String) -> Void

    func makeUIViewController(context: Context) -> BarcodeCaptureViewController {
        let controller = BarcodeCaptureViewController()
        controller.onCode = onCode
        return controller
    }

    func updateUIViewController(_ controller: BarcodeCaptureViewController, context: Context) {
        controller.onCode = onCode
        controller.setTorch(isTorchOn)
    }
}
