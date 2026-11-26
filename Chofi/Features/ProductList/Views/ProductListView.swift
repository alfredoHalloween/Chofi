//
//  ProductListView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct ProductListView: View {
    @State private var viewModel = ProductListViewModel()
    @State private var isCreatingProduct = false

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
        .toolbar {
            // upsert solo actúa sobre una lista cargada.
            if case .loaded = viewModel.state {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isCreatingProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Nuevo producto")
                }
            }
        }
        .sheet(isPresented: $isCreatingProduct) {
            ProductFormView(mode: .create, onSaved: viewModel.upsert)
        }
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
