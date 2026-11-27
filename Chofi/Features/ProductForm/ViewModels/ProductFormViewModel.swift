//
//  ProductFormViewModel.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation
import Observation

enum ProductFormMode {
    case create
    case edit(Product)
}

@MainActor
@Observable
final class ProductFormViewModel {

    var barcode = ""
    var name = ""
    var selectedBrand: Brand?
    /// Precio en centavos de MXN. `0` significa vacío.
    var priceCents = 0

    private(set) var saveState: LoaderState<Product> = .idle

    private let mode: ProductFormMode
    private let dataManager: ProductsDataManagerProtocol
    private let initialValues: Values

    /// Valores del formulario, para detectar cambios.
    /// La marca se compara por `id` y el precio por centavos.
    private struct Values: Equatable {
        var barcode = ""
        var name = ""
        var selectedBrandId: Int?
        var priceCents = 0
    }

    init(
        mode: ProductFormMode,
        dataManager: ProductsDataManagerProtocol = ProductsDataManager()
    ) {
        self.mode = mode
        self.dataManager = dataManager

        var values = Values()
        var brand: Brand?
        if case .edit(let product) = mode {
            // La marca sale del producto, sin pedir nada al servicio.
            brand = product.brand
            values.barcode = product.barcode ?? ""
            values.name = product.name
            values.selectedBrandId = product.brand.id
            values.priceCents = CurrencyInput.cents(from: product.price)
        }
        initialValues = values
        barcode = values.barcode
        name = values.name
        selectedBrand = brand
        priceCents = values.priceCents
    }

    var title: String {
        switch mode {
        case .create: return "Nuevo producto"
        case .edit: return "Editar producto"
        }
    }

    /// Petición lista para enviar, o nil si algún campo es inválido.
    var request: ProductRequest? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              let brandId = selectedBrand?.id,
              let price = parsedPrice
        else { return nil }

        let trimmedBarcode = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        return ProductRequest(
            barcode: trimmedBarcode.isEmpty ? nil : trimmedBarcode,
            name: trimmedName,
            brandId: brandId,
            price: price
        )
    }

    var hasChanges: Bool {
        currentValues != initialValues
    }

    var canSave: Bool {
        guard request != nil, !saveState.isLoading else { return false }
        if case .edit = mode { return hasChanges }
        return true
    }

    /// Envía el formulario. Regresa el producto guardado, o nil si falló o ya se estaba guardando.
    func save() async -> Product? {
        guard !saveState.isLoading, let request else { return nil }

        saveState = .loading

        do {
            let product: Product
            switch mode {
            case .create:
                product = try await dataManager.createProduct(request)
            case .edit(let original):
                product = try await dataManager.updateProduct(id: original.id, request)
            }
            saveState = .loaded(product)
            return product
        } catch {
            saveState = .error(error.localizedDescription)
            return nil
        }
    }

    func dismissError() {
        guard saveState.error != nil else { return }
        saveState = .idle
    }

    // MARK: - Privado

    private var currentValues: Values {
        Values(barcode: barcode, name: name, selectedBrandId: selectedBrand?.id, priceCents: priceCents)
    }

    /// Precio > 0. Los centavos ya garantizan 2 decimales como máximo.
    private var parsedPrice: Decimal? {
        priceCents > 0 ? CurrencyInput.decimal(fromCents: priceCents) : nil
    }
}
