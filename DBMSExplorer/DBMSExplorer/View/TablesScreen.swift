//
//  TablesScreen.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI

struct TablesScreen: View {
    let title: String
    
    var body: some View {
        List {
            ForEach(1...10, id: \.self) { index in
                Text("Table \(index)")
            }
            .onDelete(perform: deleteItem)
        }
        .navigationTitle(title)
    }
    
    private func deleteItem(at index: IndexSet) {
        print(index)
    }
}
