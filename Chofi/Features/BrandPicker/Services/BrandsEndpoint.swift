//
//  BrandsEndpoint.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation
import NetworkKit

enum BrandsEndpoint: Endpoint {
    case brands  // GET /brand

    var baseURL: String {
        APIConfig.baseURL
    }

    var path: String {
        switch self {
        case .brands: return "/brand"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .brands: return .get
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .brands: return nil
        }
    }

    var headers: [String: String] {
        APIConfig.headers
    }
}
