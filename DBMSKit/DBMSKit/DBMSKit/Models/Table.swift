//
//  Table.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 29.11.22.
//

import Foundation

struct TableSchema: Codable {
    var name: String
    var fields: [Field]

    private enum CodingKeys: String, CodingKey {
        case name
        case fields
    }
    
    init(name: String, fields: [Field]) {
        self.name = name
        self.fields = fields
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        fields = try values.decode([Field].self, forKey: .fields)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(fields, forKey: .fields)
    }

    func toString() -> String {
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

    func toString() -> String {
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
    var values: String

    private enum CodingKeys: String, CodingKey {
        case id
        case previousId
        case nextId
        case values
    }

    init(string: String, id: Int) {
        self.id = id
        self.previousId = id - 1
        self.nextId = id - 1
        values = string
        values.append(String(repeating: Character(Constants.blankSpaceCharacter), count: (Constants.pageSize - string.count)))
    }

    init(id: Int) {
        self.id = id
        values = String(repeating: Character(Constants.blankSpaceCharacter), count: Constants.pageSize)
        nextId = id + 1

        previousId = id == 0 ? id : (id - 1)
    }
    
    init(id: Int, previousId: Int, nextId: Int, values: String) {
        self.id = id
        self.previousId = previousId
        self.nextId = nextId
        self.values = values
    }

    init(from decoder: Decoder) throws {
        let decoderValues = try decoder.container(keyedBy: CodingKeys.self)
        id = try decoderValues.decode(Int.self, forKey: .id)
        previousId = try decoderValues.decode(Int.self, forKey: .previousId)
        nextId = try decoderValues.decode(Int.self, forKey: .nextId)
        values = try decoderValues.decode(String.self, forKey: .values)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(previousId, forKey: .previousId)
        try container.encode(nextId, forKey: .nextId)
        try container.encode(values, forKey: .values)
    }
}

struct Field: Codable {
    let name: String
    let type: DBType
    let defaultValue: String?

    private enum CodingKeys: String, CodingKey {
        case name
        case type
        case defaultValue
    }

    init(name: String, type: DBType, defaultValue: String?) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }

    init(from decoder: Decoder) throws {
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
    
    func encode(to encoder: Encoder) throws {
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
