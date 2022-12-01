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
            print(error.localizedDescription)
        }
    }
    
    func createTable(query: Query) {
        var fileUrl = baseUrl
        var schemaUrl = baseUrl
        let jsonEncoder = JSONEncoder()
        
        guard let tableName = query.subject as? String else {
            print("Wrong table name format")
            return
        }
        
        fileUrl.appendPathComponent(tableName)
        fileUrl.appendPathExtension("bin")
        
        schemaUrl.appendPathComponent(tableName + "Schema")
        schemaUrl.appendPathExtension("bin")
        
        guard !manager.fileExists(atPath: fileUrl.path),
              !manager.fileExists(atPath: schemaUrl.path) else {
            print("Table \(tableName) already exists")
            return
        }
        
        guard let fields = query.objects as? [Field] else {
            print("Couldn't parse table fields")
            return
        }
        
        let rootPage = Page(id: 1, previousId: 0, nextId: 2, values: [])
        let tableSchema = TableSchema(name: tableName, fields: fields)
        let tableData = TableData(pages: [rootPage])

        do {
            let schemaData = try jsonEncoder.encode(tableSchema)
            let tableJsonData = try jsonEncoder.encode(tableData)

            manager.createFile(atPath: schemaUrl.path, contents: schemaData, attributes: nil)
            manager.createFile(atPath: fileUrl.path, contents: tableJsonData, attributes: nil)
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func dropTable(query: Query) {
        guard let tableNames = query.subjects as? [String] else {
            print("No table names provided to drop")
            return
        }
        
        for tableName in tableNames {
            var fileUrl = baseUrl
            var schemaUrl = baseUrl
            
            fileUrl.appendPathComponent(tableName)
            fileUrl.appendPathExtension("bin")
            
            schemaUrl.appendPathComponent(tableName + "Schema")
            schemaUrl.appendPathExtension("bin")
            
            guard manager.fileExists(atPath: fileUrl.path),
                  manager.fileExists(atPath: schemaUrl.path) else {
                print("Table \(tableName) doesn't exist")
                return
            }

            do {
                try manager.removeItem(at: schemaUrl)
                try manager.removeItem(at: fileUrl)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    func listTables() {
        do {
            let names = try manager.contentsOfDirectory(atPath: baseUrl.path)
            for name in names {
                if !StringHelpers.stringContainsString(base: name, searched: "Schema"),
                   name != ".DS_Store" {
                    print(StringHelpers.removeCharactersFromEnd(string: name, count: 4))
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func tableInfo(query: Query) {
        var fileUrl = baseUrl
        var schemaUrl = baseUrl
        let jsonDecoder = JSONDecoder()

        guard let tableName = query.subject as? String else {
            print("Wrong table name format")
            return
        }

        fileUrl.appendPathComponent(tableName)
        fileUrl.appendPathExtension("bin")
        
        schemaUrl.appendPathComponent(tableName + "Schema")
        schemaUrl.appendPathExtension("bin")
        
        guard manager.fileExists(atPath: fileUrl.path),
              manager.fileExists(atPath: schemaUrl.path) else {
            print("Table \(tableName) doesn't exist")
            return
        }

        guard let schemaData = manager.contents(atPath: schemaUrl.path),
              let tableData = manager.contents(atPath: fileUrl.path) else {
            print("File \(tableName).bin is empty")
            return
        }
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            let data = try jsonDecoder.decode(TableData.self, from: tableData)

            print(schema.toString())
            print(data.toString())
            print("Data is \(tableData.count) bytes\n")
        } catch let error {
            print(error.localizedDescription)
        }
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
