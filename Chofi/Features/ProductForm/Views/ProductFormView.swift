//
//  ProductFormView.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import SwiftUI

/// Formulario para crear o editar un producto. Se presenta en `.sheet`.
struct ProductFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: ProductFormViewModel
    @State private var isScanning = false
    @State private var scannedCode: String?
    @State private var isConfirmingDiscard = false

    private let onSaved: (Product) -> Void

    init(
        mode: ProductFormMode,
        dataManager: ProductsDataManagerProtocol = ProductsDataManager(),
        onSaved: @escaping (Product) -> Void
    ) {
        _viewModel = State(initialValue: ProductFormViewModel(mode: mode, dataManager: dataManager))
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Código de barras") {
                    HStack {
                        TextField("Opcional", text: $viewModel.barcode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            isScanning = true
                        } label: {
                            Image(systemName: "barcode.viewfinder")
                                .font(.title2)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Escanear código de barras")
                    }
                }

                Section("Nombre") {
                    TextField("Nombre del producto", text: $viewModel.name)
                }

                Section("ID de marca") {
                    TextField("ID de marca", text: $viewModel.brandIdText)
                        .keyboardType(.numberPad)
                }

                Section("Precio") {
                    TextField("0.00", text: $viewModel.priceText)
                        .keyboardType(.decimalPad)
                }
            }
            .disabled(viewModel.saveState.isLoading)
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .confirmationDialog("¿Descartar los cambios?", isPresented: $isConfirmingDiscard, titleVisibility: .hidden) {
                Button("Descartar cambios", role: .destructive) {
                    dismiss()
                }
                Button("Seguir editando", role: .cancel) {}
            }
            .alert("No se pudo guardar el producto", isPresented: errorAlertBinding) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.saveState.error ?? "")
            }
            .fullScreenCover(isPresented: $isScanning) {
                BarcodeScannerView(scannedCode: $scannedCode)
            }
            .onChange(of: scannedCode) { _, code in
                // Cancelar el escáner deja el binding en nil y no cambia el campo.
                guard let code else { return }
                viewModel.barcode = code
                scannedCode = nil
            }
        }
        .interactiveDismissDisabled(viewModel.hasChanges || viewModel.saveState.isLoading)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancelar") {
                if viewModel.hasChanges {
                    isConfirmingDiscard = true
                } else {
                    dismiss()
                }
            }
            .disabled(viewModel.saveState.isLoading)
        }

        ToolbarItem(placement: .confirmationAction) {
            if viewModel.saveState.isLoading {
                ProgressView()
            } else {
                Button("Guardar") {
                    Task {
                        guard let product = await viewModel.save() else { return }
                        onSaved(product)
                        dismiss()
                    }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.saveState.error != nil },
            set: { isPresented in
                if !isPresented { viewModel.dismissError() }
            }
        )
    }
}

// MARK: - Preview

#if DEBUG
/// Responde al instante con el producto que se envía, sin tocar el servicio.
private struct PreviewProductsDataManager: ProductsDataManagerProtocol {
    func fetchProducts() async throws -> [Product] { Product.samples }

    func createProduct(_ request: ProductRequest) async throws -> Product {
        try await Task.sleep(for: .seconds(1))
        return Product(id: 99, name: request.name, price: request.price, barcode: request.barcode,
                       brand: Brand(id: request.brandId, name: "Marca \(request.brandId)"))
    }

    func updateProduct(id: Int, _ request: ProductRequest) async throws -> Product {
        try await Task.sleep(for: .seconds(1))
        return Product(id: id, name: request.name, price: request.price, barcode: request.barcode,
                       brand: Brand(id: request.brandId, name: "Marca \(request.brandId)"))
    }
}

#Preview("Nuevo producto") {
    ProductFormView(mode: .create, dataManager: PreviewProductsDataManager()) { _ in }
}

#Preview("Editar producto") {
    ProductFormView(mode: .edit(Product.samples[0]), dataManager: PreviewProductsDataManager()) { _ in }
}
#endif
