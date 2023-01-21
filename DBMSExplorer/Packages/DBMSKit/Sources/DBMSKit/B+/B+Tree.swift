//
//  B+Tree.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 19.01.23.
//

import Foundation

final class BPlusTree: Codable {
    let m: Int
    var root: InternalNode?
    var firstLeaf: LeafNode?
    var height: Int = 0
    
    var isEmpty: Bool {
        return firstLeaf == nil
    }
    
    var midPoint: Int {
        return Int((m + 1) / 2) - 1
    }

    private enum CodingKeys: String, CodingKey {
        case m
        case root
        case firstLeaf
        case height
    }
    
    init(m: Int) {
        self.m = m
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        m = try values.decode(Int.self, forKey: .m)
        height = try values.decode(Int.self, forKey: .height)
        root = try values.decode(InternalNode.self, forKey: .root)
        firstLeaf = try values.decode(LeafNode.self, forKey: .firstLeaf)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(m, forKey: .m)
        root?.height = height
        root?.depth = 0
        try container.encode(root, forKey: .root)
        try container.encode(firstLeaf, forKey: .firstLeaf)
        try container.encode(height, forKey: .height)
    }
    
    // MARK: Public
    
    func search(key: String) -> [DictionaryPair]? {
        height = 0
        if (isEmpty) {
            return nil
        }
        
        guard let leafNode = root == nil ? firstLeaf : findLeafNode(node: nil, key) else {
            print("Couldn't find a leaf node")
            return nil
        }
        
        let values = leafNode.dictionary
        let addresses = values.filter { pair in
            pair.key == key
        }
        
        return addresses
    }
    
    func insert(key: String, value: Adress) {
        guard !isEmpty else {
            firstLeaf = LeafNode(m: m, pair: DictionaryPair(key: key, value: value), parent: nil)
            return
        }
        
        guard let leafNode = root == nil ? firstLeaf : findLeafNode(node: nil, key) else {
            print("Couldn't find a leaf node")
            return
        }
        
        if leafNode.insert(pair: DictionaryPair(key: key, value: value)) {
            return
        }
        
        leafNode.dictionary.append(DictionaryPair(key: key, value: value))
        leafNode.sortDictionary()
        let half = splitArray(array: leafNode.dictionary, split: midPoint)
        leafNode.dictionary = ArrayHelpers.removeLastFewElements(array: leafNode.dictionary, count: leafNode.pairs - midPoint)
        
        if let parent = leafNode.parent {
            parent.keys.append(half[0].key)
            parent.keys.sort()
        } else {
            let parent = InternalNode(m: m, keys: [half[0].key], parent: nil)
            leafNode.parent = parent
            parent.appendChild(child: leafNode)
        }
        
        var newLeafNode = LeafNode(m: m, dictionary: half, parent: leafNode.parent)
        let nodeIndex = (leafNode.parent?.childNodes.firstIndex(where: { node in
            node === leafNode
        }) ?? 0) + 1
        leafNode.parent?.insertChildNode(node: newLeafNode, index: nodeIndex)
        
        guard root != nil else {
            root = leafNode.parent
            return
        }
        
        var internalNode = leafNode.parent
        while (internalNode != nil) {
            if let internalNode = internalNode,
               internalNode.isOverfull {
                splitInternalNode(internalNode: internalNode)
            } else {
                break
            }
            internalNode = internalNode?.parent;
        }
    }
    
    // MARK: Private
    
    // Find the leaf node
    private func findLeafNode(node: InternalNode?, _ key: String) -> LeafNode? {
        guard let root = root else {
            print("No root")
            return nil
        }
        
        let parentNode: InternalNode
        if let node = node {
            parentNode = node
        } else {
            parentNode = root
        }
        
        var index = -1
        for i in 0 ..< (parentNode.degree - 1) {
            if key < parentNode.keys[i] {
                index = i
                break
            }
        }
        
        let child = parentNode.childNodes[index == -1 ? parentNode.degree - 1 : index]
        if let childLeaf = child as? LeafNode {
            return childLeaf
        } else if let childInternal = child as? InternalNode {
            height += 1
            return findLeafNode(node: childInternal, key)
        }
        
        return nil
    }
    
    private func splitArray<T>(array: [T], split: Int) -> [T] {
        let half = Array(array[split..<array.count])
        array.dropLast(array.count - split)
        
        return half
    }
    
    private func splitInternalNode(internalNode: InternalNode) {
        let parent = internalNode.parent
        let midpoint = midPoint
        let newParentKey = internalNode.keys[midpoint]
        let halfKeys = splitArray(array: internalNode.keys, split: midpoint)
        internalNode.keys = ArrayHelpers.removeLastFewElements(array: internalNode.keys, count: internalNode.keys.count - midPoint)
        let halfNodes = splitArray(array: internalNode.childNodes, split: midpoint)
        internalNode.childNodes = ArrayHelpers.removeLastFewElements(array: internalNode.childNodes, count: internalNode.childNodes.count - midPoint)

        internalNode.degree = internalNode.childNodes.count
        let sibling = InternalNode(m: m, keys: halfKeys, nodes: halfNodes, parent: internalNode.parent)
        for halfNode in halfNodes {
            halfNode.parent = sibling
        }
        
        guard let parent = parent else {
            let keys = [newParentKey]
            var newRoot = InternalNode(m: m, keys: keys, parent: nil)
            newRoot.appendChild(child: internalNode)
            newRoot.appendChild(child: sibling)
            root = newRoot
            internalNode.parent = newRoot
            sibling.parent = newRoot
            return
        }
        
        parent.keys.append(newParentKey)
        parent.keys.sort()
        let nodeIndex = (internalNode.parent?.childNodes.firstIndex(where: { node in
            node === internalNode
        }) ?? 0) + 1
        parent.insertChildNode(node: sibling, index: nodeIndex)
        sibling.parent = parent
    }
}
