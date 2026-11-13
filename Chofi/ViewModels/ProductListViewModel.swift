//
//  ProductListViewModel.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation

final class ProductListViewModel: ObservableObject {
    @Published var searchText = ""

    private let products: [Product]

    init(products: [Product] = Product.samples) {
        self.products = products
    }

    var filteredProducts: [Product] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return products }
        return products.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
