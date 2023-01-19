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

class InternalNode: Node {
    let maxDegree: Int
    let minDegree: Int
    var degree: Int
    var leftSibling: InternalNode?
    var rightSibling: InternalNode?
    var keys: [String] = []
    var childNodes: [Node] = []
    
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
