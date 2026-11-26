//
//  ProductListViewModel.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProductListViewModel {

    var searchText = ""

    private(set) var state: LoaderState<[Product]> = .idle

    private let dataManager: ProductsDataManagerProtocol

    init(dataManager: ProductsDataManagerProtocol = ProductsDataManager()) {
        self.dataManager = dataManager
    }

    var filteredProducts: [Product] {
        let products = state.data ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return products }
        return products.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    func fetchProducts() async {
        guard !state.isLoading else { return }

        state = .loading

        do {
            let products = try await dataManager.fetchProducts()
            state = .loaded(products)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
