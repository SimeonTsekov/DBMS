//
//  TableScreen.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 22.01.23.
//

import SwiftUI

struct TableScreen: View {
    @ObservedObject private var tableViewModel: TableViewModel
    
    init(tableViewModel: TableViewModel) {
        self.tableViewModel = tableViewModel
    }

    var body: some View {
        List{
            Section {
                ForEach(tableViewModel.schema.fields) { field in
                    Text("\(field.name): \(field.type.rawValue) -> \(field.defaultValue ?? "none")")
                        .foregroundColor(Color.primary.opacity(0.75))
                }
            } header: {
                Text("Schema")
            }
            
            Section {
                ForEach(tableViewModel.rows) { row in
                    Text(row.toString())
                        .foregroundColor(Color.primary.opacity(0.75))
                }
            } header: {
                Text("Values")
            }
        }
        .navigationTitle(tableViewModel.tableName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
            } label: {
                Image(systemName: "plus")
            }
        }
        .onAppear {
            tableViewModel.fetchRows()
        }
    }
}
