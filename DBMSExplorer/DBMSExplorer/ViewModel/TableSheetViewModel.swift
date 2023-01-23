//
//  TableSheetViewModel.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 23.01.23.
//

import Foundation
import DBMSKit

class TableSheetViewModel: ObservableObject {
    var manager: QueryManager
    @Published var tableName = ""
    @Published var fields: [Field] = []

    init(manager: QueryManager) {
        self.manager = manager
        fields.append(Field(name: "", type: .dbInt, defaultValue: ""))
    }
    
    func createTable() {
        guard tableName != "" else {
            assertionFailure("Provide table name")
            return
        }

        var fieldsString = ""
        for field in fields {
            fieldsString.append("\(field.name): \(field.type.rawValue)\(field.defaultValue != "" ? " DEFAULT \(field.defaultValue!)" : ""), ")
        }
        fieldsString.removeLast(2)
        manager.handleQuery(query: "CREATE \(tableName)(\(fieldsString))")
    }
    
    func addField() {
        fields.append(Field(name: "", type: .dbInt, defaultValue: ""))
    }
}
