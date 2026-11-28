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
    static let baseURL = "https://cbf5-2806-2f0-a5c1-d7c7-54ec-9c58-5567-6b0f.ngrok-free.app"

    /// Evita que ngrok responda con su página HTML de advertencia en lugar del JSON.
    static let headers = ["ngrok-skip-browser-warning": "true"]
}
