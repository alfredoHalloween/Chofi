//
//  ProductDetailView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct ProductDetailView: View {
    let product: Product

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
            Text(product.price.formatted(.currency(code: "MXN")))
                .font(.title2)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProductDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProductDetailView(product: Product.samples[0])
        }
    }
}
