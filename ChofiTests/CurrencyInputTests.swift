//
//  CurrencyInputTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

final class CurrencyInputTests: XCTestCase {

    // MARK: - text(fromCents:)

    func test_textFromCents_zero_isEmpty() {
        XCTAssertEqual(CurrencyInput.text(fromCents: 0), "")
    }

    func test_textFromCents_formatsWithSymbolSeparatorsAndTwoDecimals() {
        XCTAssertEqual(CurrencyInput.text(fromCents: 2), "$0.02")
        XCTAssertEqual(CurrencyInput.text(fromCents: 2850), "$28.50")
        XCTAssertEqual(CurrencyInput.text(fromCents: 125050), "$1,250.50")
        XCTAssertEqual(CurrencyInput.text(fromCents: 99_999_999), "$999,999.99")
    }

    // MARK: - cents(from: String)

    func test_centsFromText_extractsDigits() {
        XCTAssertEqual(CurrencyInput.cents(from: "$28.50"), 2850)
    }

    func test_centsFromText_withoutDigits_isZero() {
        XCTAssertEqual(CurrencyInput.cents(from: "abc"), 0)
        XCTAssertEqual(CurrencyInput.cents(from: ""), 0)
    }

    func test_centsFromText_ignoresLeadingZeros() {
        XCTAssertEqual(CurrencyInput.cents(from: "$0.005"), 5)
    }

    func test_centsFromText_exceedingMax_isNil() {
        XCTAssertNil(CurrencyInput.cents(from: "$999,999.990"))
    }

    // MARK: - Decimal

    func test_decimalFromCents() {
        XCTAssertEqual(CurrencyInput.decimal(fromCents: 2850), Decimal(string: "28.50"))
    }

    func test_centsFromDecimal() {
        XCTAssertEqual(CurrencyInput.cents(from: Decimal(string: "28.5")!), 2850)
    }

    func test_centsFromDecimal_roundsPlain() {
        XCTAssertEqual(CurrencyInput.cents(from: Decimal(string: "28.555")!), 2856)
    }
}
