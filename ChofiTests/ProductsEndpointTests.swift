//
//  ProductsEndpointTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 27/11/26.
//

import XCTest
@testable import Chofi

/// Fija las rutas de `ProductsEndpoint` contra el contrato de msvc-products (SPEC 12 del servicio).
final class ProductsEndpointTests: XCTestCase {

    private let request = ProductRequest(barcode: nil, name: "Producto", brandId: 1, price: 10)

    func testProductsIsGetProduct() {
        let endpoint = ProductsEndpoint.products

        XCTAssertEqual(endpoint.path, "/product")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testCreateIsPostProduct() {
        let endpoint = ProductsEndpoint.create(request)

        XCTAssertEqual(endpoint.path, "/product")
        XCTAssertEqual(endpoint.method, .post)
    }

    func testUpdateIsPutProductWithId() {
        let endpoint = ProductsEndpoint.update(id: 7, request: request)

        XCTAssertEqual(endpoint.path, "/product/7")
        XCTAssertEqual(endpoint.method, .put)
    }
}
