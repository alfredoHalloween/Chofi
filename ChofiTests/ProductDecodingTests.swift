//
//  ProductDecodingTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

final class ProductDecodingTests: XCTestCase {

    /// Misma forma que la respuesta de `GET /` del servicio.
    private let json = """
    [
      {
        "barcode": "7501040094422",
        "brand": { "id": 3, "name": "Sigma" },
        "create_at": "2026-10-29T00:00:00",
        "id": 1,
        "price": 28.00,
        "product_name": "Yoplait Disfruta Fresa 307g",
        "update_at": "2026-11-14T14:37:21"
      },
      {
        "barcode": null,
        "brand": { "id": 1, "name": "Coca Cola" },
        "create_at": "2026-10-29T14:27:59",
        "id": 3,
        "price": 21,
        "product_name": "Coca Cola Zero 600ml",
        "update_at": "2026-11-09T15:36:58"
      }
    ]
    """

    func testDecodesServiceResponse() throws {
        let products = try JSONDecoder().decode([Product].self, from: Data(json.utf8))

        XCTAssertEqual(products.count, 2)

        XCTAssertEqual(products[0].id, 1)
        XCTAssertEqual(products[0].name, "Yoplait Disfruta Fresa 307g")
        XCTAssertEqual(products[0].price, Decimal(string: "28.00"))
        XCTAssertEqual(products[0].barcode, "7501040094422")
        XCTAssertEqual(products[0].brand.name, "Sigma")

        XCTAssertEqual(products[1].id, 3)
        XCTAssertEqual(products[1].name, "Coca Cola Zero 600ml")
        XCTAssertEqual(products[1].price, Decimal(string: "21"))
        XCTAssertNil(products[1].barcode)
        XCTAssertEqual(products[1].brand.name, "Coca Cola")
    }

    /// `price` es `BigDecimal` en el servicio: `28.10` no debe llegar como `28.0999…`.
    func testDecodesPriceAsExactDecimal() throws {
        let json = """
        {
          "id": 7,
          "product_name": "Producto",
          "price": 28.10,
          "barcode": null,
          "brand": { "id": 1, "name": "Marca" }
        }
        """

        let product = try JSONDecoder().decode(Product.self, from: Data(json.utf8))

        XCTAssertEqual(product.price, Decimal(string: "28.10"))
    }
}
