//
//  ProductListViewModelTests.swift
//  ChofiTests
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import XCTest
@testable import Chofi

/// Doble de `ProductsDataManagerProtocol`. Devuelve `result` y cuenta las llamadas.
/// Con `holdsResponse` en `true`, la respuesta espera hasta llamar a `release()`.
@MainActor
private final class FakeProductsDataManager: ProductsDataManagerProtocol {
    var result: Result<[Product], Error>
    var holdsResponse = false
    private(set) var callCount = 0
    private var pending: CheckedContinuation<Void, Never>?

    init(result: Result<[Product], Error> = .success(Product.samples)) {
        self.result = result
    }

    func fetchProducts() async throws -> [Product] {
        callCount += 1
        if holdsResponse {
            await withCheckedContinuation { pending = $0 }
        }
        return try result.get()
    }

    // El listado no crea ni edita; estos métodos solo cumplen el protocolo.
    func createProduct(_ request: ProductRequest) async throws -> Product {
        fatalError("No se usa en ProductListViewModelTests")
    }

    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product {
        fatalError("No se usa en ProductListViewModelTests")
    }

    func release() {
        pending?.resume()
        pending = nil
    }
}

private struct FakeError: LocalizedError {
    var errorDescription: String? { "Sin conexión" }
}

@MainActor
final class ProductListViewModelTests: XCTestCase {

    private func makeLoadedViewModel() async -> ProductListViewModel {
        let viewModel = ProductListViewModel(dataManager: FakeProductsDataManager())
        await viewModel.fetchProducts()
        return viewModel
    }

    // MARK: - Carga

    func testInitialStateIsIdle() {
        let viewModel = ProductListViewModel(dataManager: FakeProductsDataManager())

        guard case .idle = viewModel.state else {
            return XCTFail("Se esperaba .idle y llegó \(viewModel.state)")
        }
    }

    func testFilteredProductsIsEmptyBeforeLoading() {
        let viewModel = ProductListViewModel(dataManager: FakeProductsDataManager())

        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
    }

    func testSuccessfulFetchLoadsProducts() async {
        let viewModel = await makeLoadedViewModel()

        XCTAssertEqual(viewModel.state.data, Product.samples)
    }

    func testFailedFetchSetsError() async {
        let dataManager = FakeProductsDataManager(result: .failure(FakeError()))
        let viewModel = ProductListViewModel(dataManager: dataManager)

        await viewModel.fetchProducts()

        XCTAssertEqual(viewModel.state.error, "Sin conexión")
        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
    }

    func testSecondFetchWhileLoadingDoesNotCallDataManagerAgain() async {
        let dataManager = FakeProductsDataManager()
        dataManager.holdsResponse = true
        let viewModel = ProductListViewModel(dataManager: dataManager)

        let firstFetch = Task { await viewModel.fetchProducts() }
        while dataManager.callCount == 0 { await Task.yield() }
        XCTAssertTrue(viewModel.state.isLoading)

        await viewModel.fetchProducts()
        XCTAssertEqual(dataManager.callCount, 1)

        dataManager.release()
        await firstFetch.value
        XCTAssertEqual(viewModel.state.data, Product.samples)
    }

    // MARK: - Upsert (SPEC 04)

    func testUpsertWithExistingIdReplacesProductInPlace() async {
        let viewModel = await makeLoadedViewModel()
        let original = Product.samples[1]
        let edited = Product(id: original.id, name: "Frijol bayo 1 kg", price: 40, barcode: nil, brand: original.brand)

        viewModel.upsert(edited)

        var expected = Product.samples
        expected[1] = edited
        XCTAssertEqual(viewModel.state.data, expected)
    }

    func testUpsertWithNewIdAppendsProductAtTheEnd() async {
        let viewModel = await makeLoadedViewModel()
        let new = Product(id: 99, name: "Nuevo", price: 10, barcode: nil, brand: Product.samples[0].brand)

        viewModel.upsert(new)

        XCTAssertEqual(viewModel.state.data, Product.samples + [new])
    }

    func testUpsertWhileIdleDoesNotChangeState() {
        let viewModel = ProductListViewModel(dataManager: FakeProductsDataManager())

        viewModel.upsert(Product.samples[0])

        guard case .idle = viewModel.state else {
            return XCTFail("Se esperaba .idle y llegó \(viewModel.state)")
        }
    }

    // MARK: - Filtrado sobre lo cargado (SPEC 01)

    func testEmptySearchReturnsAllProducts() async {
        let viewModel = await makeLoadedViewModel()

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testWhitespaceSearchReturnsAllProducts() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "   "

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testSearchMatchesName() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "arroz"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Arroz 1 kg"])
    }

    func testSearchIgnoresCaseAndDiacritics() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "JABON"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Jabón de barra"])
    }

    func testSearchMatchesSubstringInTheMiddle() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "ech"

        XCTAssertEqual(viewModel.filteredProducts.map(\.name), ["Leche entera 1 L"])
    }

    func testClearingSearchRestoresAllProducts() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "arroz"
        viewModel.searchText = ""

        XCTAssertEqual(viewModel.filteredProducts, Product.samples)
    }

    func testSearchWithoutMatchesReturnsEmptyList() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "zzzz"

        XCTAssertTrue(viewModel.filteredProducts.isEmpty)
    }
}
