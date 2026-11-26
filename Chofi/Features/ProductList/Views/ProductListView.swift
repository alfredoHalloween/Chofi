//
//  ProductListView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct ProductListView: View {
    @State private var viewModel = ProductListViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        TabView {
            List(viewModel.filteredProducts) { product in
                NavigationLink(value: product) {
                    ProductRowView(product: product)
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText, prompt: "Buscar por nombre")
            .tabItem {
                Label("Productos", systemImage: "cart")
            }
        }
        .navigationTitle("Productos")
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
    }
}
