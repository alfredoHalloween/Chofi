//
//  Product.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation

struct Product: Identifiable, Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let price: Double
    let barcode: String?
    let brand: Brand

    enum CodingKeys: String, CodingKey {
        case id, price, barcode, brand
        case name = "product_name"
    }

    var formattedPrice: String {
        price.formatted(.currency(code: "MXN").locale(Locale(identifier: "es_MX")))
    }
}
