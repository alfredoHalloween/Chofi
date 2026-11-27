//
//  BrandPickerViewModel.swift
//  Chofi
//
//  Created by Alfredo García on 26/11/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class BrandPickerViewModel {

    var searchText = ""

    private(set) var state: LoaderState<[Brand]> = .idle

    private let dataManager: BrandsDataManagerProtocol

    init(dataManager: BrandsDataManagerProtocol = BrandsDataManager()) {
        self.dataManager = dataManager
    }

    /// Marcas cargadas filtradas por `searchText` con las reglas de SPEC 01:
    /// subcadena, sin distinguir mayúsculas ni acentos; vacío o solo espacios devuelve todo.
    var filteredBrands: [Brand] {
        let brands = state.data ?? []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return brands }
        return brands.filter {
            $0.name.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    func fetchBrands() async {
        guard !state.isLoading else { return }

        state = .loading

        do {
            let brands = try await dataManager.fetchBrands()
            state = .loaded(brands)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
