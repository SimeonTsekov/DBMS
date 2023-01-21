//
//  InternalNode.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 19.01.23.
//

import Foundation

class Node {
    var parent: InternalNode?
    
    init(parent: InternalNode?) {
        self.parent = parent
    }
}

final class InternalNode: Node, Codable {
    let maxDegree: Int
    let minDegree: Int
    var degree: Int
    var depth = 0
    var height = 0
    var keys: [String] = []
    var childNodes: [Node] = []
    
    private enum CodingKeys: String, CodingKey {
        case maxDegree
        case minDegree
        case degree
        case depth
        case height
        case keys
        case childNodes
        case parent
    }
    
    var isDeficient: Bool {
        return degree < minDegree
    }
    
    var isLendable: Bool {
        return degree > minDegree
    }
    
    var isMergeable: Bool {
        return degree == minDegree
    }
    
    var isOverfull: Bool {
        return degree == maxDegree + 1
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        maxDegree = try values.decode(Int.self, forKey: .maxDegree)
        minDegree = try values.decode(Int.self, forKey: .minDegree)
        degree = try values.decode(Int.self, forKey: .degree)
        depth = try values.decode(Int.self, forKey: .depth)
        height = try values.decode(Int.self, forKey: .height)
        keys = try values.decode([String].self, forKey: .keys)
        if depth == height {
            childNodes = try values.decode([LeafNode].self, forKey: .childNodes)
        } else {
            childNodes = try values.decode([InternalNode].self, forKey: .childNodes)
        }
        super.init(parent: nil)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(maxDegree, forKey: .maxDegree)
        try container.encode(minDegree, forKey: .minDegree)
        try container.encode(degree, forKey: .degree)
        try container.encode(depth, forKey: .depth)
        try container.encode(height, forKey: .height)
        try container.encode(keys, forKey: .keys)
        for childNode in childNodes {
            if let childNode = childNode as? InternalNode {
                childNode.depth = depth + 1
                childNode.height = height
            }
        }
        if childNodes[0] is LeafNode {
            try container.encode(childNodes as! [LeafNode], forKey: .childNodes)
        } else {
            try container.encode(childNodes as! [InternalNode], forKey: .childNodes)
        }
        parent = nil
        try container.encode(parent, forKey: .parent)
    }
    
    init(m: Int, keys: [String], parent: InternalNode?) {
        maxDegree = m
        minDegree = Int(m / 2)
        degree = 0
        super.init(parent: parent)
        self.keys = keys
    }

    init(m: Int, keys: [String], nodes: [Node], parent: InternalNode?) {
        maxDegree = m
        minDegree = Int(m / 2)
        degree = nodes.count
        super.init(parent: parent)
        self.keys = keys
        childNodes = nodes
    }
    
    func appendChild(child: Node) {
        childNodes.append(child)
        degree += 1
    }
    
    func findIndexOfNode(node: Node) -> Int {
        let index = childNodes.firstIndex { childNode in
            childNode === node
        }
        
        return index ?? -1
    }
    
    func insertChildNode(node: Node, index: Int) {
        childNodes.insert(node, at: index)
        degree += 1
    }
    
    func removeKey(index: Int) {
        keys.remove(at: index)
    }
    
    func removeNode(index: Int) {
        childNodes.remove(at: index)
        degree -= 1
    }
    
    func removeNode(node: Node) {
        childNodes.removeAll { childNode in
            childNode === node
        }
        degree -= 1
    }
}
