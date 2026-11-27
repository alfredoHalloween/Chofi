//
//  BrandDecodingTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

final class BrandDecodingTests: XCTestCase {

    /// Misma forma que la respuesta de `GET /brand` del servicio.
    private let json = """
    [
      { "id": 18, "name": "Alen" },
      { "id": 4,  "name": "Bimbo" }
    ]
    """

    func testDecodesServiceResponse() throws {
        let brands = try JSONDecoder().decode([Brand].self, from: Data(json.utf8))

        XCTAssertEqual(brands.count, 2)

        XCTAssertEqual(brands[0].id, 18)
        XCTAssertEqual(brands[0].name, "Alen")

        XCTAssertEqual(brands[1].id, 4)
        XCTAssertEqual(brands[1].name, "Bimbo")
    }
}
