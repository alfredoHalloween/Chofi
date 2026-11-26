//
//  Product+Samples.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation

/// Datos de ejemplo para `#Preview` y pruebas. La app en ejecución usa el servicio web.
extension Product {
    static let samples: [Product] = [
        Product(id: 1, name: "Arroz 1 kg", price: 32.50, barcode: "7501000000011", brand: verde),
        Product(id: 2, name: "Frijol negro 1 kg", price: 38.90, barcode: "7501000000028", brand: verde),
        Product(id: 3, name: "Azúcar estándar 1 kg", price: 29.00, barcode: nil, brand: verde),
        Product(id: 4, name: "Aceite vegetal 900 ml", price: 45.00, barcode: "7501000000042", brand: cocina),
        Product(id: 5, name: "Leche entera 1 L", price: 27.50, barcode: "7501000000059", brand: lacteos),
        Product(id: 6, name: "Huevo blanco 12 pzas", price: 52.00, barcode: nil, brand: lacteos),
        Product(id: 7, name: "Pan de caja blanco", price: 42.00, barcode: "7501000000073", brand: panaderia),
        Product(id: 8, name: "Tortillas de maíz 1 kg", price: 24.00, barcode: nil, brand: panaderia),
        Product(id: 9, name: "Jabón de barra", price: 18.50, barcode: "7501000000097", brand: limpieza),
        Product(id: 10, name: "Detergente en polvo 1 kg", price: 36.00, barcode: "7501000000103", brand: limpieza),
        Product(id: 11, name: "Papel higiénico 4 rollos", price: 34.90, barcode: "7501000000110", brand: limpieza),
        Product(id: 12, name: "Sal de mesa 1 kg", price: 15.00, barcode: nil, brand: cocina),
        Product(id: 13, name: "Café soluble 100 g", price: 69.00, barcode: "7501000000134", brand: cocina),
        Product(id: 14, name: "Galletas Marías", price: 21.50, barcode: "7501000000141", brand: panaderia),
        Product(id: 15, name: "Refresco de cola 2 L", price: 33.00, barcode: "7501000000158", brand: bebidas),
    ]

    private static let verde = Brand(id: 1, name: "Granos del Valle")
    private static let cocina = Brand(id: 2, name: "La Cocina")
    private static let lacteos = Brand(id: 3, name: "Lácteos del Norte")
    private static let panaderia = Brand(id: 4, name: "Panadería Sol")
    private static let limpieza = Brand(id: 5, name: "Hogar Limpio")
    private static let bebidas = Brand(id: 6, name: "Bebidas MX")
}
