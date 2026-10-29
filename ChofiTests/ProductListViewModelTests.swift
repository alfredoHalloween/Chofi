//
//  ProductListViewModelTests.swift
//  ChofiTests
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import XCTest
@testable import Chofi

final class ProductListViewModelTests: XCTestCase {

    private func makeViewModel() -> ProductListViewModel {
        ProductListViewModel(products: Product.samples)
    }

    func testEmptySearchReturnsAllProducts() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testWhitespaceSearchReturnsAllProducts() {
        let viewModel = makeViewModel()
        viewModel.searchText = "   "

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testSearchMatchesName() {
        let viewModel = makeViewModel()
        viewModel.searchText = "arroz"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Arroz 1 kg"])
    }

    func testSearchIgnoresCaseAndDiacritics() {
        let viewModel = makeViewModel()
        viewModel.searchText = "JABON"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Jabón de barra"])
    }

    func testSearchMatchesSubstringInTheMiddle() {
        let viewModel = makeViewModel()
        viewModel.searchText = "ech"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Leche entera 1 L"])
    }

    func testClearingSearchRestoresAllProducts() {
        let viewModel = makeViewModel()
        viewModel.searchText = "arroz"
        viewModel.searchText = ""

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testSearchWithoutMatchesReturnsEmptyList() {
        let viewModel = makeViewModel()
        viewModel.searchText = "zzzz"

        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
    }
}
