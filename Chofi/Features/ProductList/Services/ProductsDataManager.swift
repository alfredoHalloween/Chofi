//
//  ProductsDataManager.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import NetworkKit

protocol ProductsDataManagerProtocol {
    func fetchProducts() async throws -> [Product]
    func createProduct(_ request: ProductRequest) async throws -> Product
    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product
}

final class ProductsDataManager: ProductsDataManagerProtocol {

    private let client: any NetworkClient

    init(client: any NetworkClient = NetworkManager()) {
        self.client = client
    }

    func fetchProducts() async throws -> [Product] {
        return try await client.request(ProductsEndpoint.products)
    }

    func createProduct(_ request: ProductRequest) async throws -> Product {
        return try await client.request(ProductsEndpoint.create(request))
    }

    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product {
        return try await client.request(ProductsEndpoint.update(id: id, request: request))
    }
}
