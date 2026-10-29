//
//  MainTabView.swift
//  Chofi
//
//  Created by Juan Alfredo García González on 29/10/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Label("Productos", systemImage: "cart")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
