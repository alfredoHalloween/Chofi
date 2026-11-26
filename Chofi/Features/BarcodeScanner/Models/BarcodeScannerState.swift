//
//  BarcodeScannerState.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 24/11/26.
//

import Foundation

/// Estados de la pantalla de lectura de código de barras.
enum BarcodeScannerState: Equatable {
    /// Estado inicial, mientras se consulta o solicita el permiso de cámara.
    case checkingPermission
    /// Cámara activa, esperando un código.
    case scanning
    /// El permiso de cámara está denegado o restringido.
    case permissionDenied
    /// No hay dispositivo de video (p. ej. el simulador).
    case cameraUnavailable
}
