//
//  BrandsDataManager.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import NetworkKit

protocol BrandsDataManagerProtocol {
    func fetchBrands() async throws -> [Brand]
}

final class BrandsDataManager: BrandsDataManagerProtocol {

    private let client: any NetworkClient

    init(client: any NetworkClient = NetworkManager()) {
        self.client = client
    }

    func fetchBrands() async throws -> [Brand] {
        return try await client.request(BrandsEndpoint.brands)
    }
}
