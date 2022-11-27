//
//  QueryManager.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

let parser = CommandParser()

class QueryManager {
    func handleQuery(query: String) {
        let tokens = StringHelpers.splitStringByCharacter(string: query, character: " ")

        guard let method = DBKeyword(rawValue: tokens[0]) else {
            print("Enter a valid query method!")
            return
        }

        let argumentTokens = ArrayHelpers.removeFirstElement(array: tokens)
        let arguments = parser.assignTypes(tokens: argumentTokens)

        switch method {
        case .dbCreate:
            createTable(arguments: arguments)
        case .dbDrop:
            dropTable(arguments: arguments)
        case .dbList:
            listTables()
        case .dbInfo:
            tableInfo(arguments: arguments)
        case .dbSelect:
            select(arguments: arguments)
        case .dbDelete:
            delete(arguments: arguments)
        case .dbInsert:
            insert(arguments: arguments)
        case .dbCreateIndex:
            createIndex(arguments: arguments)
        case .dbDropIndex:
            dropIndex(arguments: arguments)
        case .dbFrom, .dbWhere, .dbOrderBy, .dbDistinct, .dbValues:
            return
        }
    }

    private  func createTable(arguments: [Any]) {
    }

    private  func dropTable(arguments: [Any]) {
    }

    private  func listTables() {
    }

    private  func tableInfo(arguments: [Any]) {
    }

    private  func select(arguments: [Any]) {
    }

    private  func delete(arguments: [Any]) {
    }

    private  func insert(arguments: [Any]) {
    }

    private  func createIndex(arguments: [Any]) {
    }

    private  func dropIndex(arguments: [Any]) {
    }
}
