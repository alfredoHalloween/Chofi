//
//  APIConfig.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation

/// Configuración compartida de los endpoints del servicio.
enum APIConfig {
    /// URL del túnel de ngrok. Cambia cada vez que se reinicia el túnel.
    static let baseURL = "https://8bd4-2806-2f0-a5c1-d7c7-604e-b8a2-7c5b-59a1.ngrok-free.app"

    /// Evita que ngrok responda con su página HTML de advertencia en lugar del JSON.
    static let headers = ["ngrok-skip-browser-warning": "true"]
}
