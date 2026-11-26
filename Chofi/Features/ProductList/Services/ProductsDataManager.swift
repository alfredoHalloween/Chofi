//
//  ProductsDataManager.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import NetworkKit

protocol ProductsDataManagerProtocol {
    func fetchProducts() async throws -> [Product]
}

final class ProductsDataManager: ProductsDataManagerProtocol {

    private let client: any NetworkClient

    init(client: any NetworkClient = NetworkManager()) {
        self.client = client
    }

    func fetchProducts() async throws -> [Product] {
        return try await client.request(ProductsEndpoint.products)
    }
}
