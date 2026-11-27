//
//  BrandPickerViewModelTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

/// Doble de `BrandsDataManagerProtocol`. Devuelve `result` y cuenta las llamadas.
/// Con `holdsResponse` en `true`, la respuesta espera hasta llamar a `release()`.
@MainActor
private final class FakeBrandsDataManager: BrandsDataManagerProtocol {
    var result: Result<[Brand], Error>
    var holdsResponse = false
    private(set) var callCount = 0
    private var pending: CheckedContinuation<Void, Never>?

    init(result: Result<[Brand], Error> = .success(BrandPickerViewModelTests.brands)) {
        self.result = result
    }

    func fetchBrands() async throws -> [Brand] {
        callCount += 1
        if holdsResponse {
            await withCheckedContinuation { pending = $0 }
        }
        return try result.get()
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
final class BrandPickerViewModelTests: XCTestCase {

    /// En el orden del servicio (por nombre).
    nonisolated static let brands = [
        Brand(id: 18, name: "Alen"),
        Brand(id: 4, name: "Bimbo"),
        Brand(id: 1, name: "Coca Cola"),
        Brand(id: 7, name: "Nestlé"),
    ]

    private func makeLoadedViewModel() async -> BrandPickerViewModel {
        let viewModel = BrandPickerViewModel(dataManager: FakeBrandsDataManager())
        await viewModel.fetchBrands()
        return viewModel
    }

    // MARK: - Carga

    func testInitialStateIsIdle() {
        let viewModel = BrandPickerViewModel(dataManager: FakeBrandsDataManager())

        guard case .idle = viewModel.state else {
            return XCTFail("Se esperaba .idle y llegó \(viewModel.state)")
        }
    }

    func testFilteredBrandsIsEmptyBeforeLoading() {
        let viewModel = BrandPickerViewModel(dataManager: FakeBrandsDataManager())

        XCTAssertTrue(viewModel.filteredBrands.isEmpty)
    }

    func testSuccessfulFetchLoadsBrandsInServiceOrder() async {
        let viewModel = await makeLoadedViewModel()

        XCTAssertEqual(viewModel.state.data, Self.brands)
    }

    func testFailedFetchSetsError() async {
        let dataManager = FakeBrandsDataManager(result: .failure(FakeError()))
        let viewModel = BrandPickerViewModel(dataManager: dataManager)

        await viewModel.fetchBrands()

        XCTAssertEqual(viewModel.state.error, "Sin conexión")
        XCTAssertTrue(viewModel.filteredBrands.isEmpty)
    }

    func testSecondFetchWhileLoadingDoesNotCallDataManagerAgain() async {
        let dataManager = FakeBrandsDataManager()
        dataManager.holdsResponse = true
        let viewModel = BrandPickerViewModel(dataManager: dataManager)

        let firstFetch = Task { await viewModel.fetchBrands() }
        while dataManager.callCount == 0 { await Task.yield() }
        XCTAssertTrue(viewModel.state.isLoading)

        await viewModel.fetchBrands()
        XCTAssertEqual(dataManager.callCount, 1)

        dataManager.release()
        await firstFetch.value
        XCTAssertEqual(viewModel.state.data, Self.brands)
    }

    // MARK: - Filtrado (reglas de SPEC 01)

    func testSearchIgnoresDiacritics() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "nestle"

        XCTAssertEqual(viewModel.filteredBrands.map(\.name), ["Nestlé"])
    }

    func testSearchIgnoresCase() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "COCA"

        XCTAssertEqual(viewModel.filteredBrands.map(\.name), ["Coca Cola"])
    }

    func testWhitespaceSearchReturnsAllBrands() async {
        let viewModel = await makeLoadedViewModel()
        viewModel.searchText = "   "

        XCTAssertEqual(viewModel.filteredBrands, Self.brands)
    }
}
