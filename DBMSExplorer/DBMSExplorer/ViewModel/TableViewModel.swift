//
//  TableViewModel.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 22.01.23.
//

import DBMSKit
import Foundation
import SwiftUI

class TableViewModel: ObservableObject {
    var manager: QueryManager
    var tableName: String
    @Published var rows: [TableRow] = []
    @Published var schema: TableSchema
    
    init(tableName: String, manager: QueryManager) {
        self.tableName = tableName
        self.manager = manager
        schema = TableSchema(name: tableName, fields: [])
        guard let result = manager.handleQuery(query: "INFO \(tableName)") as? TableSchema else {
            return
        }
        schema = result
    }
    
    func fetchRows() {
        guard let result = manager.handleQuery(query: "SELECT * FROM \(tableName)") as? [TableRow] else {
            return
        }
        rows = result
    }
}
