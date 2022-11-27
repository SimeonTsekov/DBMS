//
//  ArrayHelpers.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

class ArrayHelpers {
    static func removeFirstElement<T>(array: [T]) -> [T] {
        var new: [T] = []
        
        for i in 1..<array.count {
            new.append(array[i])
        }
        
        return new
    }

    static func removeLastElement<T>(array: [T]) -> [T] {
        var new: [T] = []
        
        for i in 0..<(array.count - 1) {
            new.append(array[i])
        }
        
        return new
    }
}
