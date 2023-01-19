//
//  LeafNode.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 19.01.23.
//

import Foundation

final class LeafNode: Node, Codable {
    let maxPairs: Int
    let minPairs: Int
    var pairs: Int
    var dictionary: [DictionaryPair] = [] {
        didSet {
            pairs = dictionary.count
        }
    }

    private enum CodingKeys: String, CodingKey {
        case maxPairs
        case minPairs
        case pairs
        case leftSibling
        case rightSibling
        case dictionary
        case parent
    }

    var isDeficient: Bool{
        return pairs < minPairs;
    }
    
    var isFull: Bool {
        return pairs >= maxPairs;
    }
    
    var isLendable: Bool {
        return pairs > minPairs;
    }
    
    var isMergeable: Bool {
        return pairs == minPairs;
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        maxPairs = try values.decode(Int.self, forKey: .maxPairs)
        minPairs = try values.decode(Int.self, forKey: .minPairs)
        pairs = try values.decode(Int.self, forKey: .pairs)
        dictionary = try values.decode([DictionaryPair].self, forKey: .dictionary)
        super.init(parent: nil)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(maxPairs, forKey: .maxPairs)
        try container.encode(minPairs, forKey: .minPairs)
        try container.encode(pairs, forKey: .pairs)
        try container.encode(dictionary, forKey: .dictionary)
        parent = nil
        try container.encode(parent, forKey: .parent)
    }

    init(m: Int, pair: DictionaryPair, parent: InternalNode?) {
        maxPairs = m - 1
        minPairs = Int(m / 2) - 1
        pairs = 0
        super.init(parent: parent)
        dictionary.append(pair)
    }
    
    init(m: Int, dictionary: [DictionaryPair], parent: InternalNode?) {
        maxPairs = m - 1
        minPairs = Int(m / 2) - 1
        pairs = dictionary.count
        super.init(parent: parent)
        self.dictionary = dictionary
        self.parent = parent
    }
    
    func insert(pair: DictionaryPair) -> Bool {
        if isFull {
            return false
        } else {
            dictionary.append(pair)
            sortDictionary()
            return true
        }
    }
    
    func sortDictionary() {
        dictionary.sort { lhs, rhs in
            return lhs.key < rhs.key
        }
    }
}

final class DictionaryPair: Comparable, Codable {
    let key: String
    let value: Adress

    private enum CodingKeys: String, CodingKey {
        case key
        case value
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        key = try values.decode(String.self, forKey: .key)
        value = try values.decode(Adress.self, forKey: .value)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(value, forKey: .value)
    }

    init(key: String, value: Adress) {
        self.key = key
        self.value = value
    }
    
    static func == (lhs: DictionaryPair, rhs: DictionaryPair) -> Bool {
        return lhs.key == rhs.key
    }
    
    static func < (lhs: DictionaryPair, rhs: DictionaryPair) -> Bool {
        return lhs.key < rhs.key
    }
}

final class Adress: Codable {
    let page: Int
    let row: Int
    
    private enum CodingKeys: String, CodingKey {
        case page
        case row
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        page = try values.decode(Int.self, forKey: .page)
        row = try values.decode(Int.self, forKey: .row)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
        try container.encode(row, forKey: .row)
    }
    
    init(page: Int, row: Int) {
        self.page = page
        self.row = row
    }
}
