//
//  BrandPickerView.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import SwiftUI

struct BrandPickerView: View {
    @Binding private var selection: Brand?
    @State private var viewModel: BrandPickerViewModel
    @Environment(\.dismiss) private var dismiss

    init(selection: Binding<Brand?>,
         dataManager: BrandsDataManagerProtocol = BrandsDataManager()) {
        _selection = selection
        _viewModel = State(initialValue: BrandPickerViewModel(dataManager: dataManager))
    }

    var body: some View {
        content
            .navigationTitle("Marca")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchBrands()
            }
    }

    @ViewBuilder
    private var content: some View {
        @Bindable var viewModel = viewModel

        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            List(viewModel.filteredBrands, id: \.id) { brand in
                Button {
                    selection = brand
                    dismiss()
                } label: {
                    HStack {
                        Text(brand.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if brand.id == selection?.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityAddTraits(brand.id == selection?.id ? .isSelected : [])
            }
            .searchable(text: $viewModel.searchText, prompt: "Buscar marca")
            .overlay {
                if viewModel.filteredBrands.isEmpty, !viewModel.searchText.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            }
        case .error(let message):
            ContentUnavailableView {
                Label("No se pudieron cargar las marcas", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Reintentar") {
                    Task {
                        await viewModel.fetchBrands()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Preview

/// Doble para el preview: devuelve marcas fijas sin tocar la red.
private struct PreviewBrandsDataManager: BrandsDataManagerProtocol {
    func fetchBrands() async throws -> [Brand] {
        [
            Brand(id: 18, name: "Alen"),
            Brand(id: 4, name: "Bimbo"),
            Brand(id: 1, name: "Coca Cola"),
            Brand(id: 7, name: "Nestlé"),
            Brand(id: 3, name: "Sigma"),
        ]
    }
}

#Preview {
    NavigationStack {
        BrandPickerView(selection: .constant(Brand(id: 4, name: "Bimbo")),
                        dataManager: PreviewBrandsDataManager())
    }
}
