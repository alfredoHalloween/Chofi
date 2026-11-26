//
//  Product+Samples.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation

extension Product {
    static let samples: [Product] = [
        sample("Arroz 1 kg", price: 32.50, image: "arroz"),
        sample("Frijol negro 1 kg", price: 38.90, image: "frijol"),
        sample("Azúcar estándar 1 kg", price: 29.00, image: "azucar"),
        sample("Aceite vegetal 900 ml", price: 45.00, image: "aceite"),
        sample("Leche entera 1 L", price: 27.50, image: "leche"),
        sample("Huevo blanco 12 pzas", price: 52.00, image: "huevo"),
        sample("Pan de caja blanco", price: 42.00, image: "pan"),
        sample("Tortillas de maíz 1 kg", price: 24.00, image: "tortillas"),
        sample("Jabón de barra", price: 18.50, image: "jabon"),
        sample("Detergente en polvo 1 kg", price: 36.00, image: "detergente"),
        sample("Papel higiénico 4 rollos", price: 34.90, image: "papel"),
        sample("Sal de mesa 1 kg", price: 15.00, image: "sal"),
        sample("Café soluble 100 g", price: 69.00, image: "cafe"),
        sample("Galletas Marías", price: 21.50, image: "galletas"),
        sample("Refresco de cola 2 L", price: 33.00, image: "refresco"),
    ]

    private static func sample(_ name: String, price: Double, image: String) -> Product {
        Product(
            id: UUID(),
            name: name,
            price: price,
            imageURL: URL(string: "https://example.com/images/\(image).jpg")
        )
    }
}
