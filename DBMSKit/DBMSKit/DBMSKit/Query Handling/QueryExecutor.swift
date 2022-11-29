//
//  QueryExecutor.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 29.11.22.
//

import Foundation
import System

class QueryExecutor {
    var baseUrl: URL = URL(fileURLWithPath: "")
    let manager = FileManager.default

    init() {
        guard let url = manager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        baseUrl = url
        baseUrl.appendPathComponent(".DBMSKit")
        
        do {
            try manager.createDirectory(at: baseUrl, withIntermediateDirectories: true, attributes: nil)
        } catch let error {
            print(error)
        }
    }
    
    func createTable(query: Query) {
        var fileUrl = baseUrl
        var schemaUrl = baseUrl
        
        guard let tableName = query.subject as? String else {
            assertionFailure("Wrong table name format")
            return
        }
        
        fileUrl.appendPathComponent(tableName)
        fileUrl.appendPathExtension("bin")
        
        schemaUrl.appendPathComponent(tableName + "Schema")
        schemaUrl.appendPathExtension("bin")
        
        guard !manager.fileExists(atPath: fileUrl.path),
              !manager.fileExists(atPath: schemaUrl.path) else {
            assertionFailure("Table already exists")
            return
        }
        
        guard let fields = query.objects as? [Field] else {
            assertionFailure("Couldn't parse table fields")
            return
        }
        
        let rootPage = Page(id: 1, previousId: 0, nextId: 2, values: [])
        let tableSchema = TableSchema(name: tableName, fields: fields)
        let tableData = TableData(pages: [rootPage])

        manager.createFile(atPath: schemaUrl.path, contents: Data(base64Encoded: String(describing: tableSchema)), attributes: nil)
        manager.createFile(atPath: fileUrl.path, contents: Data(base64Encoded: String(describing: tableData)), attributes: nil)
    }

    func dropTable(query: Query) {
    }

    func listTables(query: Query) {
    }

    func tableInfo(query: Query) {
    }

    func select(query: Query) {
    }

    func delete(query: Query) {
    }

    func insert(query: Query) {
    }

    func createIndex(query: Query) {
    }

    func dropIndex(query: Query) {
    }
}
