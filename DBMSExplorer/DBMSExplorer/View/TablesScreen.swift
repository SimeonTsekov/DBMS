//
//  TablesScreen.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI

struct TablesScreen: View {
    @ObservedObject private var tablesViewModel: TablesViewModel
    let title: String
    
    init(title: String, tablesViewModel: TablesViewModel) {
        self.title = title
        self.tablesViewModel = tablesViewModel
    }
    
    var body: some View {
        NavigationView {
            List{
                ForEach(tablesViewModel.tables) { table in
                    NavigationLink(table.name, destination: TableScreen(tableViewModel: TableViewModel(tableName: table.name, manager: tablesViewModel.manager)))
                        .foregroundColor(Color.primary.opacity(0.75))
                }
                .onDelete(perform: deleteItem)
            }
            .onAppear {
                tablesViewModel.getTableData()
            }
            .navigationTitle(title)
            .toolbar {
                Button {
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deleteItem(at index: IndexSet) {
        tablesViewModel.dropTable(at: index)
    }
}
