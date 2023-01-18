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

    static func removeRepeatingOccurences<T: Equatable>(array: [T]) -> [T] {
        var unique: [T] = []
        
        for item in array {
            if !unique.contains(item) {
                unique.append(item)
            }
        }
        
        return unique
    }
}

extension Array where Element == TableRow {
    
    internal mutating func quickSort(factor: String) {
        quickSort(&self[...], factor)
    }
    
    private func quickSort(_ array: inout ArraySlice<TableRow>, _ factor: String) {
        if array.count < 2 {
            return
        }
        sortPivot(in: &array, with: factor)
        let pivot = partition(&array, factor)
        quickSort(&array[array.startIndex..<pivot], factor)
        quickSort(&array[pivot + 1..<array.endIndex], factor)
    }
    
    private func sortPivot(in array: inout ArraySlice<Element>, with factor: String) {
        let startPoint = array.startIndex
        let midPoint = (array.startIndex + array.endIndex) / 2
        let endPoint = array.endIndex - 1
        
        if array[startPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" > array[midPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" {
            array.swapAt(startPoint, midPoint)
        }
        if array[midPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" > array[endPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" {
            array.swapAt(midPoint, endPoint)
        }
        if array[startPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" > array[midPoint].properties.first(where: { element in
            element.name == factor
        })?.value ?? "" {
            array.swapAt(startPoint, midPoint)
        }
    }
    
    private func partition(_ array: inout ArraySlice<Element>, _ factor: String) -> ArraySlice<Element>.Index {
        let midPoint = (array.startIndex + array.endIndex) / 2
        array.swapAt(midPoint, array.startIndex)
        let pivot = array[array.startIndex]
        var lower = array.startIndex
        var upper = array.endIndex - 1
        repeat {
            while lower < array.endIndex - 1 && array[lower].properties.first(where: { element in
                element.name == factor
            })?.value ?? "" <= pivot.properties.first(where: { element in
                element.name == factor
            })?.value ?? "" {
                lower += 1
            }
            while array[upper].properties.first(where: { element in
                element.name == factor
            })?.value ?? "" > pivot.properties.first(where: { element in
                element.name == factor
            })?.value ?? "" {
                upper -= 1
            }
            if lower < upper {
                array.swapAt(lower, upper)
            }
        } while lower < upper
        array.swapAt(array.startIndex, upper)
        return upper
    }
}
