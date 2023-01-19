//
//  LeafNode.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 19.01.23.
//

import Foundation

typealias Adress = (page: Int, row: Int)

class LeafNode: Node {
    let maxPairs: Int
    let minPairs: Int
    var pairs: Int
    var leftSibling: LeafNode?
    var rightSibling: LeafNode?
    var dictionary: [DictionaryPair] = [] {
        didSet {
            pairs = dictionary.count
        }
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

class DictionaryPair: Comparable {
    let key: String
    let value: Adress
    
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
