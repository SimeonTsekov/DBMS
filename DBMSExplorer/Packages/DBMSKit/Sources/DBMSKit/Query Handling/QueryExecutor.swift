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
    func createTable(query: Query) -> String {
        let jsonEncoder = JSONEncoder()
        
        guard let tableName = query.subject as? String else {
            return "Wrong table name format"
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName, shouldExist: false) else {
            return "Couldn't construct URLs"
        }
        
        guard let fields = query.objects as? [Field] else {
            return "Couldn't parse table fields"
        }
        
        let rootPage = Page(id: 1)
        let tableSchema = TableSchema(name: tableName, fields: fields)
        let tableData = TableData(pages: [rootPage])
        
        do {
            let schemaData = try jsonEncoder.encode(tableSchema)
            let tableJsonData = try jsonEncoder.encode(tableData)
            
            manager.createFile(atPath: fileTableInfo.schemaURL.path, contents: schemaData, attributes: nil)
            manager.createFile(atPath: fileTableInfo.dataURL.path, contents: tableJsonData, attributes: nil)
            return "Table \(tableName) successfully created"
        } catch let error {
            return error.localizedDescription
        }
        return "Creation of table \(tableName) failed"
    }
    
    func dropTable(query: Query) -> String {
        guard let tableNames = query.subjects as? [String] else {
            return "No table names provided to drop"
        }
        
        for tableName in tableNames {
            guard let fileTableInfo = getTableFileInfo(for: tableName) else {
                return "Couldn't construct URLs"
            }
            
            do {
                try manager.removeItem(at: fileTableInfo.schemaURL)
                try manager.removeItem(at: fileTableInfo.dataURL)
            } catch let error {
                return error.localizedDescription
            }
        }
        
        return "Table deletion successfull"
    }
    
    func listTables() -> [String] {
        var tables: [String] = []
        do {
            let names = try manager.contentsOfDirectory(atPath: baseUrl.path)
            for name in names {
                if !StringHelpers.stringContainsString(base: name, searched: "Schema"),
                   !StringHelpers.stringContainsString(base: name, searched: "_"),
                   name != ".DS_Store" {
                    tables.append(StringHelpers.removeCharactersFromEnd(string: name, count: 4))
                }
            }
        } catch let error {
            return [error.localizedDescription]
        }
        return tables
    }
    
    func tableInfo(query: Query) -> TableSchema? {
        let jsonDecoder = JSONDecoder()
        
        guard let tableName = query.subject as? String else {
            print("Wrong table name format")
            return nil
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return nil
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path),
              let tableData = manager.contents(atPath: fileTableInfo.dataURL.path) else {
            print("File \(tableName).bin is empty")
            return nil
        }
        do {
            let schema = try jsonDecoder.decode(TableSchema.self, from: schemaData)
            let data = try jsonDecoder.decode(TableData.self, from: tableData)
            
            return schema
        } catch let error {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func select(query: Query) -> Any? {
        guard let tableName = query.object as? String else {
            print("Wrong table name format")
            return nil
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            print("Couldn't construct URLs")
            return nil
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            print("Error when determining size")
            return nil
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            print("File \(fileTableInfo.schemaURL).bin is empty")
            return nil
        }
        
        let jsonDecoder = JSONDecoder()
        let fileDescriptor = FileHandle(forUpdatingAtPath: fileTableInfo.dataURL.path)
        var currentPage = 1
        var filteredRows: [TableRow] = []
        var fields: [String] = []
        
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
                            return []
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
                    fields.append(stringRepresentation)
                    print(stringRepresentation)
                }
                return fields
            }
            
            while remainingData > Constants.fullPageSize {
                let offset = UInt64((Constants.pageOffset + (currentPage - 1) * Constants.fullPageSize))
                try fileDescriptor?.seek(toOffset: currentPage == 1 ? offset : offset + 1)
                
                guard let pageBinaryData = try fileDescriptor?.read(upToCount: Constants.fullPageSize) else {
                    print("Could not read page data")
                    try fileDescriptor?.close()
                    return []
                }
                
                let page = try jsonDecoder.decode(Page.self, from: pageBinaryData)
                let pageData = helper.removeBlankSpaces(string: page.values)
                var pageValues = StringHelpers.splitStringByCharacter(string: pageData, character: Character(Constants.rowSeparatorCharacter))
                pageValues = ArrayHelpers.removeLastElement(array: pageValues)
                let rows = helper.convertStringsToRows(strings: pageValues, schema: schema)
                if !(query.predicates?.isEmpty ?? true) {
                    filteredRows = helper.filterRowsByPredicate(rows: rows, predicates: query
                        .predicates ?? [])
                } else {
                    filteredRows = rows
                }
                
                currentPage += 1
                remainingData -= Constants.fullPageSize
            }
            
            if query.distinctSelection {
                filteredRows = ArrayHelpers.removeRepeatingOccurences(array: filteredRows)
            }
            
            if let orderFactor = query.orderFactor {
                filteredRows.quickSort(factor: orderFactor)
            }
            
            if query.subjects?[0] as? String == "*" {
                return filteredRows
            }
            
            for row in filteredRows {
                var stringRepresentation = ""
                for property in row.properties {
                    if let subjects = query.subjects as? [String],
                       subjects.contains(property.name) {
                        stringRepresentation.append("\(property.value) ")
                    }
                }
                fields.append(stringRepresentation)
            }
            return fields
        } catch let error {
            return error.localizedDescription
        }
        
        return fields
    }
    
    func delete(query: Query) -> String {
        guard let tableName = query.object as? String else {
            return "Wrong table name format"
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            return "Couldn't construct URLs"
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            return "Error when determining size"
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            return "File \(fileTableInfo.schemaURL).bin is empty"
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
                    try fileDescriptor?.close()
                    return "Could not read page data"
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
            return "Row deletion successful"
        } catch let error {
            return error.localizedDescription
        }
        return "Row deletion failed"
    }
    
    func insert(query: Query) -> String {
        guard let table = query.object as? TableInsertScehma else {
            return "Wrong table name format"
        }
        
        guard let rowsToInsert = query.subjects as? [TableValue] else {
            return "Couldn't parse values"
        }
        
        let tableName = table.name
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            return "Couldn't construct URLs"
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path)else {
            return "File \(tableName).bin is empty"
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            return "Error when determining size"
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
                    try fileDescriptor?.close()
                    return "Could not read page data"
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
                    try fileDescriptor?.close()
                    return "Insertion successful"
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
            return "Insertion successful"
        }  catch let error {
            return error.localizedDescription
        }
    }
    
    func createIndex(query: Query) -> String {
        guard let tableName = query.objects?[0] as? String else {
            return "Wrong table name format"
        }
        
        guard let indexField = query.objects?[1] as? String else {
            return "Wrong index field name format"
        }
        
        guard let indexName = query.subject as? String else {
            return "Wrong index name format"
        }
        
        guard let fileTableInfo = getTableFileInfo(for: tableName) else {
            return "Couldn't construct URLs"
        }
        
        guard var remainingData = Int(exactly: manager.sizeOfFile(atPath: fileTableInfo.dataURL.path) ?? 0) else {
            return "Error when determining size"
        }
        
        guard let schemaData = manager.contents(atPath: fileTableInfo.schemaURL.path) else {
            return "File \(fileTableInfo.schemaURL).bin is empty"
        }
        
        var indexUrl = baseUrl
        indexUrl.appendPathComponent("\(indexName)_\(tableName)\(indexField)")
        indexUrl.appendPathExtension("bin")
        
        guard !FileManager.default.fileExists(atPath: indexUrl.path) else {
            return "Index \(indexName) already exists"
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
                    try fileDescriptor?.close()
                    return "Could not read page data"
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
                        return "Couldn,t get row value for indexed column"
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
            return "Index created successfully"
        } catch let error {
            return error.localizedDescription
        }
        return "Index creation failed"
    }
    
    func dropIndex(query: Query) -> String {
        guard let indexNames = query.subjects as? [String] else {
            return "No index names provided to drop"
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
                return error.localizedDescription
            }
        }
        return "Index deletion successful"
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
