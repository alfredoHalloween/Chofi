//
//  ProductsEndpoint.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation
import NetworkKit

enum ProductsEndpoint: Endpoint {
    case products                                  // GET  /product
    case create(ProductRequest)                    // POST /product
    case update(id: Int, request: ProductRequest)  // PUT  /product/{id}

    var baseURL: String {
        APIConfig.baseURL
    }

    var path: String {
        switch self {
        case .products: return "/product"
        case .create: return "/product"
        case .update(let id, _): return "/product/\(id)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .products: return .get
        case .create: return .post
        case .update: return .put
        }
    }

    var body: (any Encodable)? {
        switch self {
        case .products: return nil
        case .create(let request), .update(_, let request): return request
        }
    }

    var headers: [String: String] {
        APIConfig.headers
    }
}
