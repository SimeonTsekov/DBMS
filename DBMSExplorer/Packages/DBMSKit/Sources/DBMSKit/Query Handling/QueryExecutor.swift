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
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
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
        var filteredRows: [TableRow] = []
        
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            
            if query.predicates?.count == 3,
               let results = selectFromIndex(query: query) {
                var resultRows: [TableRow] = []
                var pageNum = 0
                var page: Page = Page(id: 0)
                var rows: [TableRow] = []
                for result in results {
                    if result.value.page != pageNum {
                        pageNum = result.value.page
                        let offset = UInt64((Constants.pageOffset + (currentPage - 1) * Constants.fullPageSize))
                        try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                        
                        guard let pageBinaryData = try fileDescriptor?.read(upToCount: Constants.fullPageSize) else {
                            print("Could not read page data")
                            try fileDescriptor?.close()
                            return
                        }
                        
                        page = try jsonDecoder.decode(Page.self, from: pageBinaryData)
                        let pageData = helper.removeBlankSpaces(string: page.values)
                        var pageValues = StringHelpers.splitStringByCharacter(string: pageData, character: Character(Constants.rowSeparatorCharacter))
                        pageValues = ArrayHelpers.removeLastElement(array: pageValues)
                        rows = helper.convertStringsToRows(strings: pageValues, schema: schema)
                    }
                    resultRows.append(rows[result.value.row])
                }
                
                for row in resultRows {
                    var stringRepresentation = ""
                    for property in row.properties {
                        if let subjects = query.subjects as? [String],
                           subjects.contains(property.name) {
                            stringRepresentation.append("\(property.value) ")
                        }
                    }
                    print(stringRepresentation)
                }
                return
            }
            
            while remainingData > Constants.fullPageSize {
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
                filteredRows = helper.filterRowsByPredicate(rows: rows, predicates: query
                    .predicates ?? [])
                
                currentPage += 1
                remainingData -= Constants.fullPageSize
            }
            
            if query.distinctSelection {
                filteredRows = ArrayHelpers.removeRepeatingOccurences(array: filteredRows)
            }
            
            if let orderFactor = query.orderFactor {
                filteredRows.quickSort(factor: orderFactor)
            }
            
            for row in filteredRows {
                var stringRepresentation = ""
                for property in row.properties {
                    if let subjects = query.subjects as? [String],
                       subjects.contains(property.name) {
                        stringRepresentation.append("\(property.value) ")
                    }
                }
                print(stringRepresentation)
            }
        } catch let error {
            print(error)
        }
    }
    
    func delete(query: Query) {
        guard let tableName = query.object as? String else {
            print("Wrong table name format")
            return
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            print("Error when determining size")
            return
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            print("File \(fileTableInfo.schemaURL).bin is empty")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        let jsonEncoder = JSONEncoder()
        let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
        
        var currentPage = 1
        
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            while remainingData > Constants.fullPageSize {
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
                    .predicates ?? [], exclude: true)
                
                if filteredRows.count != rows.count {
                    var newData = ""
                    for row in filteredRows {
                        var rowRepresentation = ""
                        for fieldProperty in row.toRow() {
                            rowRepresentation.append("\(fieldProperty),")
                        }
                        rowRepresentation = StringHelpers.removeLastCharacter(string: rowRepresentation)
                        rowRepresentation.append(Character(Constants.rowSeparatorCharacter))
                        newData.append(rowRepresentation)
                    }
                    let newPage = Page(string: newData, id: page.id)
                    let newPageData = try jsonEncoder.encode(newPage)
                    try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                    try fileDescriptor?.write(contentsOf: newPageData)
                }
                
                currentPage += 1
                remainingData -= Constants.fullPageSize
            }
            try fileDescriptor?.close()
        } catch let error {
            print(error)
        }
    }
    
    func insert(query: Query) {
        guard let table = query.object as? TableInsertScehma else {
            print("Wrong table name format")
            return
        }
        
        guard let rowsToInsert = query.subjects as? [TableValue] else {
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
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            print("Error when determining size")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        let jsonEncoder = JSONEncoder()
        let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
        
        var currentPage = 1
        var lastRow: Int? = 0
        
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            var done = false
            
            while remainingData > Constants.fullPageSize {
                let offset = UInt64((Constants.pageOffset + (currentPage - 1) * Constants.fullPageSize))
                try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                
                guard let pageBinaryData = try fileDescriptor?.read(upToCount: Constants.fullPageSize) else {
                    print("Could not read page data")
                    try fileDescriptor?.close()
                    return
                }
                
                var page = try jsonDecoder.decode(Page.self, from: pageBinaryData)
                let controlValues = page.values
                
                for i in (lastRow ?? 0)..<rowsToInsert.count {
                    let row = constructRow(tableSchema: schema, insertSchema: table, rowToInsert: rowsToInsert[i])
                    let blankSpaces = helper.getRemainingSpace(string: page.values)
                    
                    if blankSpaces <= row.size {
                        lastRow = i
                        break
                    } else {
                        page.values = helper.writeDataToString(string: page.values, row: row.row)
                    }
                    
                    done = true
                }
                
                if page.values != controlValues {
                    let newPageData = try jsonEncoder.encode(page)
                    try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                    try fileDescriptor?.write(contentsOf: newPageData)
                }
                
                if done {
                    return
                }
                
                currentPage += 1
                remainingData -= Constants.fullPageSize
            }
            
            if lastRow != nil {
                var page = Page(id: currentPage)
                
                for i in (lastRow ?? 0)..<rowsToInsert.count {
                    let row = constructRow(tableSchema: schema, insertSchema: table, rowToInsert: rowsToInsert[i])
                    page.values = helper.writeDataToString(string: page.values, row: row.row)
                }
                
                var pageData = try jsonEncoder.encode(page)
                pageData.append(Data("]}".utf8))
                try fileDescriptor?.seek(toOffset: UInt64((Constants.pageOffset + (currentPage - 1) * Constants.fullPageSize) + 1))
                try fileDescriptor?.write(contentsOf: pageData)
            }
            try fileDescriptor?.close()
        } catch let error {
            print(error)
        }
    }
    
    func createIndex(query: Query) {
        guard let tableName = query.objects?[0] as? String else {
            print("Wrong table name format")
            return
        }
        
        guard let indexField = query.objects?[1] as? String else {
            print("Wrong index field name format")
            return
        }
        
        guard let indexName = query.subject as? String else {
            print("Wrong index name format")
            return
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            print("Error when determining size")
            return
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            print("File \(fileTableInfo.schemaURL).bin is empty")
            return
        }
        
        var indexUrl = baseUrl
        indexUrl.appendPathComponent("\(indexName)_\(tableName)\(indexField)")
        indexUrl.appendPathExtension("bin")
        
        guard !FileManager.default.fileExists(atPath: indexUrl.path) else {
            print("Index \(indexName) already exists")
            return
        }
        
        let jsonDecoder = JSONDecoder()
        let jsonEncoder = JSONEncoder()
        let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
        var fields: [DictionaryPair] = []
        var currentPage = 1
        
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            while remainingData > Constants.fullPageSize {
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
                
                var count = 0
                for row in rows {
                    guard let key = row.properties.first(where: { property in
                        property.name == indexField
                    })?.value else {
                        print("Couldn,t get row value for indexed column")
                        return
                    }
                    fields.append(DictionaryPair(key: key, value: Adress(page: currentPage, row: count)))
                    count += 1
                }
                
                currentPage += 1
                remainingData -= Constants.fullPageSize
            }
            
            let tree = constructBPTree(for: fields)
            
            let indexTreeData = try jsonEncoder.encode(tree)
            manager.createFile(atPath: indexUrl.path, contents: indexTreeData, attributes: nil)
            print("Extracted")
        } catch let error {
            print(error)
        }
    }
    
    func dropIndex(query: Query) {
        guard let indexNames = query.subjects as? [String] else {
            print("No index names provided to drop")
            return
        }
        
        for indexName in indexNames {
            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: baseUrl, includingPropertiesForKeys: nil)
                for fileurl in fileURLs {
                    if fileurl.absoluteString.contains(indexName) {
                        try manager.removeItem(at: fileurl)
                    }
                }
            } catch let error {
                print(error.localizedDescription)
            }
        }
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
    
    private func constructRow(tableSchema: TableSchema, insertSchema: TableInsertScehma, rowToInsert: TableValue) -> (row: Row, size: Int) {
        var row: Row = []
        var tempValue: String?
        var rowSize = 0
        
        for i in 0..<tableSchema.fields.count {
            for j in 0..<insertSchema.fields.count {
                if tableSchema.fields[i].name == insertSchema.fields[j] {
                    tempValue = rowToInsert.values[j]
                    break
                }
                tempValue = nil
            }
            
            if let tempValue = tempValue {
                rowSize += tempValue.count + 1
                row.append(tempValue)
            } else if let defValue = tableSchema.fields[i].defaultValue {
                rowSize += defValue.count + 1
                row.append(defValue)
            } else {
                rowSize += 2
                row.append("")
            }
        }
        rowSize -= 1
        
        return (row, rowSize)
    }
    
    private func constructBPTree(for fields: [DictionaryPair]) -> BPlusTree {
        let tree = BPlusTree(m: 3) // I'm setting it to 3 for the sake of demonstration
        for field in fields {
            tree.insert(key: field.key, value: field.value)
        }
        tree.search(key: fields[0].key)
        return tree
    }
    
    private func selectFromIndex(query: Query) -> [DictionaryPair]? {
        guard let tableName = query.object as? String else {
            print("Wrong table name format")
            return nil
        }
        
        guard let indexField = query.predicates?[0] as? String,
              let key = query.predicates?.last as? String else {
            print("Wrong index field name format")
            return nil
        }
        
        let indexName = tableName + indexField
        var indexUrl: URL?
        let jsonDecoder = JSONDecoder()
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: baseUrl, includingPropertiesForKeys: nil)
            for fileurl in fileURLs {
                if fileurl.absoluteString.contains(indexName) {
                    indexUrl = fileurl
                    break
                }
            }
            
            guard let indexUrl = indexUrl,
                  let indexData = manager.contents(atPath: indexUrl.path) else {
                return nil
            }
            
            let tree = try jsonDecoder.decode(BPlusTree.self, from: indexData)
            return tree.search(key: key)
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
        return nil
    }
}
