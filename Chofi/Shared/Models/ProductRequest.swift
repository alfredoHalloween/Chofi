//
//  ProductRequest.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation

/// Body de `POST /` y `PUT /{id}`.
struct ProductRequest: Encodable, Equatable, Sendable {
    let barcode: String?
    let name: String
    let brandId: Int         // Long en el servicio
    let price: Decimal       // BigDecimal en el servicio

    enum CodingKeys: String, CodingKey {
        case barcode, price
        case name = "product_name"
        case brandId = "brand_id"
    }

    /// `barcode` nil se envía como `"barcode": null` explícito (no se omite la llave),
    /// para que un `PUT` borre el código.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(barcode, forKey: .barcode)
        try container.encode(name, forKey: .name)
        try container.encode(brandId, forKey: .brandId)
        try container.encode(price, forKey: .price)
    }
}
