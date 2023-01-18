//
//  QueryExecutor.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 29.11.22.
//

import Foundation
import System

typealias Row = [String]
typealias TableFileInfo = (dataURL: URL, schemaURL: URL)
typealias Value = (value: String, type: DBType)

class QueryExecutor {
    var baseUrl: URL = URL(fileURLWithPath: "")
    let manager = FileManager.default
    let helper = DBHelper()

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
    
    // MARK: Queries
    func createTable(query: Query) {
        let jsonEncoder = JSONEncoder()
        
        guard let tableName = query.subject as? String else {
            print("Wrong table name format")
            return
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName, shouldExist: false) else {
            print("Couldn't construct URLs")
            return
        }

        guard let fields = query.objects as? [Field] else {
            print("Couldn't parse table fields")
            return
        }
        
        let rootPage = Page(id: 1)
        let tableSchema = TableSchema(name: tableName, fields: fields)
        let tableData = TableData(pages: [rootPage])

        do {
            let schemaData = try jsonEncoder.encode(tableSchema)
            let tableJsonData = try jsonEncoder.encode(tableData)

            manager.createFile(atPath: fileTableInfo.schemaURL.path, contents: schemaData, attributes: nil)
            manager.createFile(atPath: fileTableInfo.dataURL.path, contents: tableJsonData, attributes: nil)
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
            guard let fileTableInfo = getTableFileInfo(for: tableName) else {
                print("Couldn't construct URLs")
                return
            }

            do {
                try manager.removeItem(at: fileTableInfo.schemaURL)
                try manager.removeItem(at: fileTableInfo.dataURL)
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
        let jsonDecoder = JSONDecoder()

        guard let tableName = query.subject as? String else {
            print("Wrong table name format")
            return
        }

        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return
        }

        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path),
              let tableData = manager.contents(atPath: fileTableInfo.dataURL.path) else {
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
        guard let tableName = query.object as? String else {
            print("Wrong table name format")
            return
        }

        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return
        }

        guard var remainigData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            print("Error when determining size")
            return
        }

        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            print("File \(fileTableInfo.schemaURL).bin is empty")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
        var currentPage = 1
        
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            while remainigData > Constants.fullPageSize {
                let offset = UInt64((Constants.pageOffset + (currentPage - 1) * Constants.fullPageSize))
                try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                
                guard let pageBinaryData = try fileDescriptor?.read(upToCount: Constants.fullPageSize) else {
                    print("Could not read page data")
                    try fileDescriptor?.close()
                    return
                }
                
                let page = try jsonDecoder.decode(Page.self, from: pageBinaryData)
                let pageData = helper.removeBlankSpaces(string: page.values)
                var pageValues = StringHelpers.splitStringByCharacter(string: pageData, character: Character(Constants.rowSeparatorCharacter))
                pageValues = ArrayHelpers.removeLastElement(array: pageValues)
                let rows = helper.convertStringsToRows(strings: pageValues, schema: schema)
                let filteredRows = helper.filterRowsByPredicate(rows: rows, predicates: query
                    .predicates ?? [])
                
                for row in filteredRows {
                    var rowRepresentation = ""
                    for fieldProperty in row {
                        rowRepresentation.append("\(fieldProperty), ")
                    }
                    rowRepresentation = StringHelpers.removeCharactersFromEnd(string: rowRepresentation, count: 2)
                    print("\(rowRepresentation)\n")
                }
                
                currentPage += 1
                remainigData -= Constants.fullPageSize
            }
        } catch let error {
            print(error)
        }
    }

    func delete(query: Query) {
    }

    func insert(query: Query) {
        let jsonDecoder = JSONDecoder()
        let jsonEncoder = JSONEncoder()
        var newPage: Page?

        guard let table = query.object as? TableInsertScehma else {
            print("Wrong table name format")
            return
        }

        guard let rows = query.subjects as? [TableValue] else {
            print("Couldn't parse values")
            return
        }

        let tableName = table.name
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return
        }

        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path)else {
            print("File \(tableName).bin is empty")
            return
        }
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            var tempRow: Row = []
            var tempValue: String?
            let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
            
            guard let dataSize = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
                print("Error when determining size")
                return
            }
            var pageCount = dataSize/Constants.fullPageSize
            
            try fileDescriptor?.seek(toOffset: UInt64((Constants.pageOffset + (pageCount - 1) * Constants.fullPageSize)))
            guard let pageData = try fileDescriptor?.read(upToCount: Constants.fullPageSize) else {
                print("Could not read page data")
                try fileDescriptor?.close()
                return
            }
            var page = try jsonDecoder.decode(Page.self, from: pageData)
            
            for row in rows {
                var rowSize = 0
                for i in 0..<schema.fields.count {
                    for j in 0..<table.fields.count {
                        if schema.fields[i].name == table.fields[j] {
                            tempValue = row.values[j]
                            break
                        }
                        tempValue = nil
                    }
                    if let tempValue = tempValue {
                        rowSize += tempValue.count + 1
                        tempRow.append(tempValue)
                    } else if let defValue = schema.fields[i].defaultValue {
                        rowSize += defValue.count + 1
                        tempRow.append(defValue)
                    } else {
                        rowSize += 2
                        tempRow.append("")
                    }
                }
                rowSize -= 1
                let blankSpaces = helper.getRemainingSpace(string: page.values)
                
                if blankSpaces <= rowSize {
                    var newPageData = try jsonEncoder.encode(page)
                    newPageData.append(Data(",".utf8))
                    try fileDescriptor?.seek(toOffset: UInt64((Constants.pageOffset + (pageCount - 1) * Constants.fullPageSize)))
                    try fileDescriptor?.write(contentsOf: newPageData)
                    newPage = Page(id: page.nextId)
                    newPage!.values = helper.writeDataToString(string: newPage!.values, row: tempRow)
                    page = newPage!
                    pageCount += 1
                } else {
                    page.values = helper.writeDataToString(string: page.values, row: tempRow)
                }
                tempRow = []
            }
            
            var newPageData = try jsonEncoder.encode(page)
            if newPage != nil {
                newPageData.append(Data("]}".utf8))
                try fileDescriptor?.seek(toOffset: UInt64((Constants.pageOffset + (pageCount - 1) * Constants.fullPageSize) + 1))
            } else {
                try fileDescriptor?.seek(toOffset: UInt64((Constants.pageOffset + (pageCount - 1) * Constants.fullPageSize)))
            }
            try fileDescriptor?.write(contentsOf: newPageData)
            if pageCount > 1 {
                
            }
            try fileDescriptor?.close()
        } catch let error {
            print(error)
        }
    }

    func createIndex(query: Query) {
    }

    func dropIndex(query: Query) {
    }

    // MARK: Private
    private func getTableFileInfo(for name: String, shouldExist: Bool = true) -> TableFileInfo? {
        var dataUrl = baseUrl
        var schemaUrl = baseUrl
        
        dataUrl.appendPathComponent(name)
        dataUrl.appendPathExtension("bin")
        
        schemaUrl.appendPathComponent(name + "Schema")
        schemaUrl.appendPathExtension("bin")
        
        guard manager.fileExists(atPath: dataUrl.path) == shouldExist,
              manager.fileExists(atPath: schemaUrl.path) == shouldExist else {
            print("Table \(name) doesn't exist")
            return nil
        }
        
        return (dataUrl, schemaUrl)
    }
}
