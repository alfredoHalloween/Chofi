//
//  ProductsEndpoint.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation
import NetworkKit

enum ProductsEndpoint: Endpoint {
    case products

    /// URL del túnel de ngrok. Cambia cada vez que se reinicia el túnel.
    var baseURL: String {
        "https://805e-2806-2f0-a5c1-d7c7-604e-b8a2-7c5b-59a1.ngrok-free.app"
    }

    var path: String {
        switch self {
        case .products: return "/"
        }
    }

    /// Evita que ngrok responda con su página HTML de advertencia en lugar del JSON.
    var headers: [String: String] {
        ["ngrok-skip-browser-warning": "true"]
    }
}
