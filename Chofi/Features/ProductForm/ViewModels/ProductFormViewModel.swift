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
    var priceText = ""

    private(set) var saveState: LoaderState<Product> = .idle

    private let mode: ProductFormMode
    private let dataManager: ProductsDataManagerProtocol
    private let locale: Locale
    private let initialValues: Values

    /// Valores del formulario tal como se escriben, para detectar cambios.
    /// La marca se compara por `id`.
    private struct Values: Equatable {
        var barcode = ""
        var name = ""
        var selectedBrandId: Int?
        var priceText = ""
    }

    init(
        mode: ProductFormMode,
        dataManager: ProductsDataManagerProtocol = ProductsDataManager(),
        locale: Locale = .current
    ) {
        self.mode = mode
        self.dataManager = dataManager
        self.locale = locale

        var values = Values()
        var brand: Brand?
        if case .edit(let product) = mode {
            // La marca sale del producto, sin pedir nada al servicio.
            brand = product.brand
            values.barcode = product.barcode ?? ""
            values.name = product.name
            values.selectedBrandId = product.brand.id
            values.priceText = product.price.formatted(.number.locale(locale).grouping(.never))
        }
        initialValues = values
        barcode = values.barcode
        name = values.name
        selectedBrand = brand
        priceText = values.priceText
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
        Values(barcode: barcode, name: name, selectedBrandId: selectedBrand?.id, priceText: priceText)
    }

    /// Precio > 0 con máximo 2 decimales, usando el separador decimal del locale.
    /// Todo el texto debe ser numérico: `Decimal(string:)` por sí solo ignora el texto sobrante ("12a" → 12).
    private var parsedPrice: Decimal? {
        let text = priceText.trimmingCharacters(in: .whitespaces)
        let separator = NSRegularExpression.escapedPattern(for: locale.decimalSeparator ?? ".")
        guard text.range(of: "^[0-9]+(\(separator)[0-9]{1,2})?$", options: .regularExpression) != nil,
              let price = Decimal(string: text, locale: locale), price > 0
        else { return nil }
        return price
    }
}
