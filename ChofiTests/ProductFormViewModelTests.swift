//
//  ProductFormViewModelTests.swift
//  ChofiTests
//
//  Created by Alfredo García on 26/11/26.
//

import XCTest
@testable import Chofi

/// Doble de `ProductsDataManagerProtocol` que registra los requests del formulario.
/// Con `holdsResponse` en `true`, la respuesta espera hasta llamar a `release()`.
@MainActor
private final class FakeProductFormDataManager: ProductsDataManagerProtocol {
    var result: Result<Product, Error>
    var holdsResponse = false
    private(set) var createdRequests: [ProductRequest] = []
    private(set) var updatedRequests: [(id: Int, request: ProductRequest)] = []
    private var pending: CheckedContinuation<Void, Never>?

    var callCount: Int { createdRequests.count + updatedRequests.count }

    init(result: Result<Product, Error> = .success(Product.samples[0])) {
        self.result = result
    }

    func fetchProducts() async throws -> [Product] {
        fatalError("No se usa en ProductFormViewModelTests")
    }

    func createProduct(_ request: ProductRequest) async throws -> Product {
        createdRequests.append(request)
        return try await respond()
    }

    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product {
        updatedRequests.append((id, request))
        return try await respond()
    }

    func release() {
        pending?.resume()
        pending = nil
    }

    private func respond() async throws -> Product {
        if holdsResponse {
            await withCheckedContinuation { pending = $0 }
        }
        return try result.get()
    }
}

private struct FakeError: LocalizedError {
    var errorDescription: String? { "Sin conexión" }
}

@MainActor
final class ProductFormViewModelTests: XCTestCase {

    private func makeViewModel(
        mode: ProductFormMode = .create,
        dataManager: FakeProductFormDataManager? = nil
    ) -> ProductFormViewModel {
        ProductFormViewModel(mode: mode, dataManager: dataManager ?? FakeProductFormDataManager())
    }

    private func fillValidForm(_ viewModel: ProductFormViewModel) {
        viewModel.barcode = "7501040094422"
        viewModel.name = "Yoplait Disfruta Fresa 307g"
        viewModel.selectedBrand = sigma
        viewModel.priceCents = 2850
    }

    private let sigma = Brand(id: 3, name: "Sigma")

    // MARK: - Estado inicial

    func testCreateStartsEmptyAndCannotSave() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.title, "Nuevo producto")
        XCTAssertEqual(viewModel.barcode, "")
        XCTAssertEqual(viewModel.name, "")
        XCTAssertNil(viewModel.selectedBrand)
        XCTAssertEqual(viewModel.priceCents, 0)
        XCTAssertFalse(viewModel.canSave)
    }

    func testEditPreloadsProductAndCannotSaveWithoutChanges() {
        let product = Product.samples[0]   // Arroz 1 kg, $32.50, brand 1
        let viewModel = makeViewModel(mode: .edit(product))

        XCTAssertEqual(viewModel.title, "Editar producto")
        XCTAssertEqual(viewModel.barcode, "7501000000011")
        XCTAssertEqual(viewModel.name, "Arroz 1 kg")
        XCTAssertEqual(viewModel.selectedBrand, product.brand)
        XCTAssertEqual(viewModel.priceCents, 3250)
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)
    }

    func testEditChangingPriceAndRestoringOriginalCentsHasNoChanges() {
        let viewModel = makeViewModel(mode: .edit(Product.samples[0]))   // $32.50

        viewModel.priceCents = 2990
        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.canSave)

        viewModel.priceCents = 3250
        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)
    }

    func testEditWithNilBarcodePreloadsEmptyText() {
        let viewModel = makeViewModel(mode: .edit(Product.samples[2]))

        XCTAssertEqual(viewModel.barcode, "")
    }

    func testEditWithChangesCanSave() {
        let viewModel = makeViewModel(mode: .edit(Product.samples[0]))

        viewModel.name = "Arroz integral 1 kg"

        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.canSave)
    }

    // MARK: - Marca (SPEC 05)

    func testCreateWithoutBrandHasNoRequestEvenWithValidNameAndPrice() {
        let viewModel = makeViewModel()
        viewModel.name = "Yoplait Disfruta Fresa 307g"
        viewModel.priceCents = 2850

        XCTAssertNil(viewModel.selectedBrand)
        XCTAssertNil(viewModel.request)
        XCTAssertFalse(viewModel.canSave)
    }

    func testEditChoosingAnotherBrandHasChangesAndSendsNewBrandId() {
        let viewModel = makeViewModel(mode: .edit(Product.samples[0]))   // brand 1

        viewModel.selectedBrand = Brand(id: 2, name: "La Cocina")

        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.canSave)
        XCTAssertEqual(viewModel.request?.brandId, 2)
    }

    func testEditChoosingOriginalBrandAgainHasNoChanges() {
        let product = Product.samples[0]
        let viewModel = makeViewModel(mode: .edit(product))

        viewModel.selectedBrand = Brand(id: 2, name: "La Cocina")
        viewModel.selectedBrand = product.brand

        XCTAssertFalse(viewModel.hasChanges)
        XCTAssertFalse(viewModel.canSave)
    }

    // MARK: - Validación

    func testValidFormBuildsRequest() {
        let viewModel = makeViewModel()
        fillValidForm(viewModel)

        XCTAssertEqual(
            viewModel.request,
            ProductRequest(barcode: "7501040094422", name: "Yoplait Disfruta Fresa 307g", brandId: 3, price: Decimal(string: "28.50")!)
        )
        XCTAssertTrue(viewModel.canSave)
    }

    func testEmptyOrWhitespaceNameIsInvalid() {
        let viewModel = makeViewModel()
        fillValidForm(viewModel)

        for name in ["", "   "] {
            viewModel.name = name
            XCTAssertNil(viewModel.request, "name: \"\(name)\"")
        }
    }

    func testZeroPriceCentsIsInvalid() {
        let viewModel = makeViewModel()
        fillValidForm(viewModel)
        viewModel.priceCents = 0

        XCTAssertNil(viewModel.request)
        XCTAssertFalse(viewModel.canSave)
    }

    func testWhitespaceBarcodeIsSentAsNil() {
        let viewModel = makeViewModel()
        fillValidForm(viewModel)
        viewModel.barcode = "  "

        XCTAssertNotNil(viewModel.request)
        XCTAssertNil(viewModel.request?.barcode)
    }

    func testPriceCentsAreSentAsDecimal() {
        let viewModel = makeViewModel()
        fillValidForm(viewModel)
        viewModel.priceCents = 2850

        XCTAssertEqual(viewModel.request?.price, Decimal(string: "28.50"))
    }

    // MARK: - Guardado

    func testCreateSaveCallsCreateProductAndReturnsProduct() async {
        let dataManager = FakeProductFormDataManager()
        let viewModel = makeViewModel(dataManager: dataManager)
        fillValidForm(viewModel)
        let expectedRequest = viewModel.request

        let saved = await viewModel.save()

        XCTAssertEqual(dataManager.createdRequests, [expectedRequest!])
        XCTAssertTrue(dataManager.updatedRequests.isEmpty)
        XCTAssertEqual(saved, Product.samples[0])
        XCTAssertEqual(viewModel.saveState.data, Product.samples[0])
    }

    func testEditSaveCallsUpdateProductWithProductId() async {
        let product = Product.samples[4]   // id 5
        let dataManager = FakeProductFormDataManager(result: .success(product))
        let viewModel = makeViewModel(mode: .edit(product), dataManager: dataManager)
        viewModel.priceCents = 2990

        let saved = await viewModel.save()

        XCTAssertTrue(dataManager.createdRequests.isEmpty)
        XCTAssertEqual(dataManager.updatedRequests.map(\.id), [5])
        XCTAssertEqual(dataManager.updatedRequests.first?.request.price, Decimal(string: "29.90"))
        XCTAssertEqual(saved, product)
    }

    func testFailedSaveSetsErrorAndKeepsFields() async {
        let dataManager = FakeProductFormDataManager(result: .failure(FakeError()))
        let viewModel = makeViewModel(dataManager: dataManager)
        fillValidForm(viewModel)

        let saved = await viewModel.save()

        XCTAssertNil(saved)
        XCTAssertEqual(viewModel.saveState.error, "Sin conexión")
        XCTAssertEqual(viewModel.barcode, "7501040094422")
        XCTAssertEqual(viewModel.name, "Yoplait Disfruta Fresa 307g")
        XCTAssertEqual(viewModel.selectedBrand, sigma)
        XCTAssertEqual(viewModel.priceCents, 2850)

        viewModel.dismissError()
        guard case .idle = viewModel.saveState else {
            return XCTFail("Se esperaba .idle y llegó \(viewModel.saveState)")
        }
        XCTAssertTrue(viewModel.canSave)
    }

    func testSecondSaveWhileSavingDoesNotCallDataManagerAgain() async {
        let dataManager = FakeProductFormDataManager()
        dataManager.holdsResponse = true
        let viewModel = makeViewModel(dataManager: dataManager)
        fillValidForm(viewModel)

        let firstSave = Task { await viewModel.save() }
        while dataManager.callCount == 0 { await Task.yield() }
        XCTAssertTrue(viewModel.saveState.isLoading)
        XCTAssertFalse(viewModel.canSave)

        let secondSave = await viewModel.save()
        XCTAssertNil(secondSave)
        XCTAssertEqual(dataManager.callCount, 1)

        dataManager.release()
        let saved = await firstSave.value
        XCTAssertEqual(saved, Product.samples[0])
    }
}
