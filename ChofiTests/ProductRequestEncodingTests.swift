//
//  ProductRequestEncodingTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

final class ProductRequestEncodingTests: XCTestCase {

    private func encodedJSON(_ request: ProductRequest) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(request), as: UTF8.self)
    }

    func testEncodesServiceKeys() throws {
        let request = ProductRequest(
            barcode: "7501040094422",
            name: "Yoplait Disfruta Fresa 307g",
            brandId: 3,
            price: Decimal(string: "28.5")!
        )

        let json = try encodedJSON(request)

        XCTAssertEqual(
            json,
            #"{"barcode":"7501040094422","brand_id":3,"price":28.5,"product_name":"Yoplait Disfruta Fresa 307g"}"#
        )
    }

    func testNilBarcodeIsEncodedAsExplicitNull() throws {
        let request = ProductRequest(barcode: nil, name: "Producto", brandId: 1, price: 10)

        let json = try encodedJSON(request)

        XCTAssertTrue(json.contains(#""barcode":null"#), json)
    }

    func testPriceIsEncodedWithoutRoundingErrors() throws {
        let request = ProductRequest(barcode: nil, name: "Producto", brandId: 1, price: Decimal(string: "28.1")!)

        let json = try encodedJSON(request)

        XCTAssertTrue(json.contains(#""price":28.1"#), json)
        XCTAssertFalse(json.contains("28.09"), json)
    }
}
