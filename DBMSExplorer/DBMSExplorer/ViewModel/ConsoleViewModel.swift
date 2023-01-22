//
//  ConsoleViewModel.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 22.01.23.
//

import Foundation

import DBMSKit
import Foundation
import SwiftUI

class ConsoleViewModel: ObservableObject {
    var manager: QueryManager
    @Published var query: String = ""
    @Published var output: [String] = []
    
    init(manager: QueryManager) {
        self.manager = manager
    }
    
    func sendQuery() {
        output.append(query)
        if let result = manager.handleQuery(query: query) as? String {
            output.append(result)
        } else if let result = manager.handleQuery(query: query) as? [String] {
            var resultString = ""
            for res in result {
                resultString.append("\(res)\n")
            }
            output.append(resultString)
        } else if let result = manager.handleQuery(query: query) as? TableSchema {
            output.append(result.toString())
        } else if let result = manager.handleQuery(query: query) as? [TableRow] {
            var resultString = ""
            for res in result {
                resultString.append("\(res.toString())\n")
            }
            resultString.removeLast()
            output.append(resultString)
        } else {
            output.append("Not a valid query")
        }
        query = ""
    }
}
