//
//  Table.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 29.11.22.
//

import Foundation

typealias TableRowProperty = (name: String, value: String, type: DBType)

public struct TableSchema: Codable {
    public var name: String
    public var fields: [Field]

    private enum CodingKeys: String, CodingKey {
        case name
        case fields
    }
    
    public init(name: String, fields: [Field]) {
        self.name = name
        self.fields = fields
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        fields = try values.decode([Field].self, forKey: .fields)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(fields, forKey: .fields)
    }

    public func toString() -> String {
        var string = "Name: \(name)\n"
        for field in fields {
            string.append("\t field: \(field.name):\(field.type.rawValue)")
            if let defaultValue = field.defaultValue {
                string.append(" default \(defaultValue)")
            }
            string.append("\n")
        }
        return string
    }
}

struct TableData: Codable {
    let pages: [Page]
    
    private enum CodingKeys: String, CodingKey {
        case pages
    }

    init(pages: [Page]) {
        self.pages = pages
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pages = try values.decode([Page].self, forKey: .pages)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pages, forKey: .pages)
    }

    public func toString() -> String {
        var count = 0
        
        for page in pages {
            count += page.values.filter({ value in
                value != "0"
            }).count
        }

        return "Table has \(count) values"
    }
}

struct Page: Codable {
    let id: Int
    let previousId: Int
    let nextId: Int
    var hash: UInt16 = 0
    var values: String {
        didSet{
            hash = StringHelpers.sdbmHash(str: values)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case previousId
        case nextId
        case values
        case hash
    }

    init(string: String, id: Int) {
        self.id = id
        self.previousId = id - 1
        self.nextId = id - 1
        values = string
        values.append(String(repeating: Character(Constants.blankSpaceCharacter), count: (Constants.pageSize - string.count)))
        hash = StringHelpers.sdbmHash(str: values)
    }

    init(id: Int) {
        self.id = id
        values = String(repeating: Character(Constants.blankSpaceCharacter), count: Constants.pageSize)
        nextId = id + 1
        hash = StringHelpers.sdbmHash(str: values)
        previousId = id == 0 ? id : (id - 1)
    }
    
    init(id: Int, previousId: Int, nextId: Int, values: String) {
        self.id = id
        self.previousId = previousId
        self.nextId = nextId
        self.values = values
        hash = StringHelpers.sdbmHash(str: values)
    }

    init(from decoder: Decoder) throws {
        let decoderValues = try decoder.container(keyedBy: CodingKeys.self)
        id = try decoderValues.decode(Int.self, forKey: .id)
        previousId = try decoderValues.decode(Int.self, forKey: .previousId)
        nextId = try decoderValues.decode(Int.self, forKey: .nextId)
        values = try decoderValues.decode(String.self, forKey: .values)
        hash = try decoderValues.decode(UInt16.self, forKey: .hash)
        let calculatedHash = StringHelpers.sdbmHash(str: values)
        guard hash == calculatedHash else {
            assertionFailure("Corrupt data!!!")
            return
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(previousId, forKey: .previousId)
        try container.encode(nextId, forKey: .nextId)
        try container.encode(hash, forKey: .hash)
        try container.encode(values, forKey: .values)
    }
}

public struct Field: Codable, Identifiable {
    public let id = UUID()
    public let name: String
    public let type: DBType
    public let defaultValue: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case defaultValue
    }

    public init(name: String, type: DBType, defaultValue: String?) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        let typeValue = try values.decode(String.self, forKey: .type)
        guard let dbType = DBType(rawValue: typeValue) else {
            print("Couldn't initialize type for \(name)")
            type = .dbString
            defaultValue = nil
            return
        }
        type = dbType
        defaultValue = try values.decodeIfPresent(String.self, forKey: .defaultValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(defaultValue, forKey: .defaultValue)
    }
}

struct TableInsertScehma {
    var name: String
    var fields: [String]
}

struct TableValue {
    var values: [String]
}

public struct TableRow: Equatable, Identifiable {
    public var id = UUID()
    
    public static func == (lhs: TableRow, rhs: TableRow) -> Bool {
        return lhs.toRow() == rhs.toRow()
    }
    
    var properties: [TableRowProperty] = []

    func toRow() -> Row {
        var row: Row = []
        
        for property in properties {
            row.append(property.value)
        }
        
        return row
    }
    
    public func toString() -> String {
        var string = ""
        for property in properties {
            string.append("\(property.value), ")
        }
        string.removeLast(2)
        return string
    }
}
