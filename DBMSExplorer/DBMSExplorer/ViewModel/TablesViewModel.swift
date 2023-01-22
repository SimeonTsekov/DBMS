//
//  TablesViewModel.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import Foundation
import SwiftUI
import DBMSKit

class TablesViewModel: ObservableObject {
    var manager: QueryManager
    @Published var tables: [Table] = []
    
    init(manager: QueryManager) {
        self.manager = manager
    }
    
    func getTableData() {
        guard let result = manager.handleQuery(query: "LIST") as? [String] else {
            return
        }
        tables = result.map({ name in
            Table(name: name)
        })
    }
    
    func dropTable(at index: IndexSet) {
        guard let arrIndex = index.first else {
            assertionFailure("Couldn,t find the specified index")
            return
        }
        manager.handleQuery(query: "DROP \(tables[arrIndex].name)")
        tables.remove(at: arrIndex)
    }
}
