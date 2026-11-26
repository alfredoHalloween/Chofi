//
//  ProductDetailView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct ProductDetailView: View {
    /// Se reemplaza con el producto que devuelve el servicio al editar.
    @State private var product: Product
    @State private var isEditing = false

    private let onProductSaved: (Product) -> Void

    init(product: Product, onProductSaved: @escaping (Product) -> Void = { _ in }) {
        _product = State(initialValue: product)
        self.onProductSaved = onProductSaved
    }

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.2))
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                }

            Text(product.name)
                .font(.title)
                .multilineTextAlignment(.center)
            Text(product.formattedPrice)
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Editar") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            ProductFormView(mode: .edit(product)) { saved in
                product = saved
                onProductSaved(saved)
            }
        }
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProductDetailView(product: Product.samples[0])
        }
    }
}
