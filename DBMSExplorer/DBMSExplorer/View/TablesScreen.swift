//
//  TablesScreen.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI

struct TablesScreen: View {
    @ObservedObject private var tablesViewModel: TablesViewModel
    @State private var showingSheet = false
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
                    showingSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingSheet, onDismiss: {
                tablesViewModel.getTableData()
            }) {
                TableSheet(tableSheetViewModel: TableSheetViewModel(manager: tablesViewModel.manager))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func deleteItem(at index: IndexSet) {
        tablesViewModel.dropTable(at: index)
    }
}
