//
//  ProductListView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.filteredProducts) { product in
                NavigationLink(value: product) {
                    ProductRowView(product: product)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Productos")
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar por nombre")
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
    }
}
