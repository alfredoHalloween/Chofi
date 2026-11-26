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
        TabView {
            content
                .task {
                    // Solo la primera vez: al volver del detalle el .task corre de nuevo.
                    guard case .idle = viewModel.state else { return }
                    await viewModel.fetchProducts()
                }
                .tabItem {
                    Label("Productos", systemImage: "cart")
                }
        }
        .navigationTitle("Productos")
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
    }

    @ViewBuilder
    private var content: some View {
        @Bindable var viewModel = viewModel

        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            List(viewModel.filteredProducts) { product in
                NavigationLink(value: product) {
                    ProductRowView(product: product)
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText, prompt: "Buscar por nombre")
        case .error(let message):
            ContentUnavailableView {
                Label("No se pudieron cargar los productos", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Reintentar") {
                    Task {
                        await viewModel.fetchProducts()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct ProductListView_Previews: PreviewProvider {
    static var previews: some View {
        ProductListView()
    }
}
