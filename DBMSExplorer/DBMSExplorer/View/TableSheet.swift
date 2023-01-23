//
//  TableSheet.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 23.01.23.
//

import SwiftUI

struct TableSheet: View {
    @ObservedObject private var tableSheetViewModel: TableSheetViewModel
    @Environment(\.dismiss) var dismiss
    
    init(tableSheetViewModel: TableSheetViewModel) {
        self.tableSheetViewModel = tableSheetViewModel
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section {
                        TextField("Enter a table name", text: $tableSheetViewModel.tableName)
                            .textFieldStyle(.plain)
                    } header: {
                        Text("Table Name")
                    }
                    
                    Section {
                        ForEach($tableSheetViewModel.fields) { $field in
                            FieldView(field: $field)
                        }
                    } header: {
                        Text("Fields")
                    }
                    
                    Section {
                        HStack {
                            Spacer()
                            Button {
                                tableSheetViewModel.createTable()
                                dismiss()
                            } label: {
                                Text("Create")
                            }
                            .buttonStyle(.borderedProminent)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color(UIColor.systemGroupedBackground))
                }
            }
            .navigationTitle("Create a Table")
            .toolbar {
                Button {
                    tableSheetViewModel.addField()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
