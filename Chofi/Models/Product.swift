//
//  Product.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import Foundation

struct Product: Identifiable, Hashable {
    let id: UUID
    let name: String
    let price: Decimal
    let imageURL: URL?
}
