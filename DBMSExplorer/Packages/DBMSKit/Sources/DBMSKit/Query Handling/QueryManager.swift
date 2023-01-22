//
//  QueryManager.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

public class QueryManager: ObservableObject {
    let parser = CommandParser()
    let executor = QueryExecutor()
    
    public init() {
        
    }
    
    public func handleQuery(query: String) -> Any? {
        let clearedQuery = StringHelpers.clearStringWhitespaces(string: query)
        let tokens = StringHelpers.splitStringByCharacter(string: clearedQuery, character: " ")

        guard let method = DBKeyword(rawValue: tokens[0]) else {
            print("Enter a valid query method!")
            return nil
        }

        let query = Query(method: method)

        let argumentTokens = ArrayHelpers.removeFirstElement(array: tokens)
        let arguments = parser.tokenize(tokens: argumentTokens)

        switch query.method {
        case .dbCreate:
            parser.parseCreate(with: arguments, for: query)
            return executor.createTable(query: query)
        case .dbDrop:
            parser.parseDrop(with: arguments, for: query)
            return executor.dropTable(query: query)
        case .dbList:
            guard arguments.isEmpty else {
                print("Can't have anything after LIST")
                return nil
            }
            return executor.listTables()
        case .dbInfo:
            parser.parseInfo(with: arguments, for: query)
            return executor.tableInfo(query: query)
        case .dbSelect:
            parser.parseSelect(with: arguments, for: query)
            return executor.select(query: query)
        case .dbDelete:
            parser.parseDelete(with: arguments, for: query)
            return executor.delete(query: query)
        case .dbInsert:
            parser.parseInsert(with: arguments, for: query)
            return executor.insert(query: query)
        case .dbCreateIndex:
            parser.parseCreateIndex(with: arguments, for: query)
            return executor.createIndex(query: query)
        case .dbDropIndex:
            parser.parseDrop(with: arguments, for: query)
            return executor.dropIndex(query: query)
        case .dbFrom, .dbWhere, .dbOrderBy, .dbDistinct, .dbValues, .dbDefault, .dbInto, .dbOn:
            return nil
        }
        
        return nil
    }
}
