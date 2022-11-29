//
//  QueryManager.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

class QueryManager {
    let parser = CommandParser()
    let executor = QueryExecutor()
    
    func handleQuery(query: String) {
        let clearedQuery = StringHelpers.clearStringWhitespaces(string: query)
        let tokens = StringHelpers.splitStringByCharacter(string: clearedQuery, character: " ")

        guard let method = DBKeyword(rawValue: tokens[0]) else {
            print("Enter a valid query method!")
            return
        }

        let query = Query(method: method)

        let argumentTokens = ArrayHelpers.removeFirstElement(array: tokens)
        let arguments = parser.tokenize(tokens: argumentTokens)

        switch query.method {
        case .dbCreate:
            parser.parseCreate(with: arguments, for: query)
            executor.createTable(query: query)
        case .dbDrop:
            executor.dropTable(query: query)
        case .dbList:
            executor.listTables(query: query)
        case .dbInfo:
            executor.tableInfo(query: query)
        case .dbSelect:
            executor.select(query: query)
        case .dbDelete:
            executor.delete(query: query)
        case .dbInsert:
            executor.insert(query: query)
        case .dbCreateIndex:
            executor.createIndex(query: query)
        case .dbDropIndex:
            executor.dropIndex(query: query)
        case .dbFrom, .dbWhere, .dbOrderBy, .dbDistinct, .dbValues, .dbDefault:
            return
        }
    }
}
