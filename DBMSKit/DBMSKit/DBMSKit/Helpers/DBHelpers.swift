//
//  DBHelpers.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 17.01.23.
//

import Foundation

typealias Predicate = [Any]

class DBHelper {
    func writeDataToString(string: String, row: Row) -> String {
        var chars = Array(string)
        
        chars.removeAll { character in
            String(character) == Constants.blankSpaceCharacter
        }
        
        for value in row {
            if value != "" {
                chars.append(contentsOf: Array(value))
            } else {
                chars.append(Character(Constants.emptyValueCharacter))
            }
            chars.append(",")
        }
        
        chars = ArrayHelpers.removeLastElement(array: chars)
        chars.append(Character(Constants.rowSeparatorCharacter))
        
        for _ in (chars.count-1)..<(Constants.pageSize - 1) {
            chars.append(Character(Constants.blankSpaceCharacter))
        }
        
        return String(chars)
    }

    func getRemainingSpace(string: String) -> Int {
        var chars = Array(string)
        
        chars.removeAll { character in
            String(character) != Constants.blankSpaceCharacter
        }
        
        return chars.count
    }

    func removeBlankSpaces(string: String) -> String {
        var chars = Array(string)
        
        chars.removeAll { character in
            String(character) == Constants.blankSpaceCharacter
        }
        
        return String(chars)
    }

    func convertStringsToRows(strings: [String], schema: TableSchema) -> [TableRow] {
        var rows: [TableRow] = []
        
        for string in strings {
            var row = TableRow(properties: [])
            let values = StringHelpers.splitStringByCharacter(string: string, character: Character(","))
            for i in 0..<values.count {
                row.properties.append((schema.fields[i].name, values[i], schema.fields[i].type))
            }
            rows.append(row)
        }
        
        return rows
    }
    
    func filterRowsByPredicate(rows: [TableRow], predicates: [Any], exclude: Bool = false) -> [Row] {
        var filteredRows: [Row] = []
        let replacedPredicates = replaceNamesWithValues(rows: rows, predicates: predicates)
        let logicalExpressions = resolveArithmeticPredicates(predicates: replacedPredicates)
        let results = resolveExpressions(predicates: logicalExpressions)

        for i in 0..<results.count {
            if results[i] == !exclude {
                filteredRows.append(rows[i].toRow())
            }
        }

        return filteredRows
    }
    
    // MARK: Private
    private func replaceNamesWithValues(rows: [TableRow], predicates: [Any]) -> [Predicate] {
        var replaced: [Any] = []
        var found = false
        var replacedRows: [Predicate] = []
        
        for row in rows {
            for predicate in predicates {
                if let name = predicate as? String {
                    for rowProperty in row.properties {
                        if name == rowProperty.name {
                            replaced.append((rowProperty.value, rowProperty.type))
                            found = true
                        }
                    }
                    if found {
                        found = false
                        continue
                    }
                    replaced.append((predicate as! String, DBType.dbString))
                } else {
                    replaced.append(predicate)
                }
            }
            replacedRows.append(replaced)
            replaced = []
        }
        
        return replacedRows
    }
    
    private func resolveArithmeticPredicates(predicates: [Predicate]) -> [Predicate] {
        var resolved: [Any] = []
        var resolvedRows: [Predicate] = []
        
        for predicate in predicates {
            for i in 0..<predicate.count {
                if let arithmeticOperator = predicate[i] as? DBToken {
                    if arithmeticOperator.isArithmeticOperator {
                        guard let leftValue = predicate[i - 1] as? Value,
                              let rightValue = predicate[i + 1] as? Value else {
                            print("Operator adjacent predicates are not values")
                            return []
                        }
                        
                        let type = leftValue.type
                        
                        
                        switch type {
                        case .dbInt:
                            let leftTypedValue = Int(leftValue.value) ?? 0 as Int
                            let rightTypedValue = Int(rightValue.value) ?? 0 as Int
                            switch arithmeticOperator {
                            case .dbEqual:
                                resolved.append(leftTypedValue == rightTypedValue)
                            case .dbLessOrEqual:
                                resolved.append(leftTypedValue <= rightTypedValue)
                            case .dbGreaterOrEqual:
                                resolved.append(leftTypedValue >= rightTypedValue)
                            case .dbNotEqual:
                                resolved.append(leftTypedValue != rightTypedValue)
                            case .dbLesser:
                                resolved.append(leftTypedValue < rightTypedValue)
                            case .dbGreater:
                                resolved.append(leftTypedValue > rightTypedValue)
                            default:
                                print("Operator is arithmetic but could not be found")
                            }
                        case .dbDate:
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            dateFormatter.dateFormat = "dd-MM-yyyy"
                            if let leftDate = dateFormatter.date(from: leftValue.value),
                               let rightDate = dateFormatter.date(from: rightValue.value) {
                                let leftTypedValue = leftDate as Date
                                let rightTypedValue = rightDate as Date
                                
                                switch arithmeticOperator {
                                case .dbEqual:
                                    resolved.append(leftTypedValue == rightTypedValue)
                                case .dbLessOrEqual:
                                    resolved.append(leftTypedValue <= rightTypedValue)
                                case .dbGreaterOrEqual:
                                    resolved.append(leftTypedValue >= rightTypedValue)
                                case .dbNotEqual:
                                    resolved.append(leftTypedValue != rightTypedValue)
                                case .dbLesser:
                                    resolved.append(leftTypedValue < rightTypedValue)
                                case .dbGreater:
                                    resolved.append(leftTypedValue > rightTypedValue)
                                default:
                                    print("Operator is arithmetic but could not be found")
                                }
                            }
                        case .dbString:
                            let leftTypedValue = leftValue.value as String
                            let rightTypedValue = rightValue.value as String
                            
                            switch arithmeticOperator {
                            case .dbEqual:
                                resolved.append(leftTypedValue == rightTypedValue)
                            case .dbLessOrEqual:
                                resolved.append(leftTypedValue <= rightTypedValue)
                            case .dbGreaterOrEqual:
                                resolved.append(leftTypedValue >= rightTypedValue)
                            case .dbNotEqual:
                                resolved.append(leftTypedValue != rightTypedValue)
                            case .dbLesser:
                                resolved.append(leftTypedValue < rightTypedValue)
                            case .dbGreater:
                                resolved.append(leftTypedValue > rightTypedValue)
                            default:
                                print("Operator is arithmetic but could not be found")
                            }
                        }
                    } else {
                        resolved.append(predicate[i])
                    }
                }
            }
            
            resolvedRows.append(resolved)
            resolved = []
        }
        
        return resolvedRows
    }
    
    private func resolveExpressions(predicates: [Predicate]) -> [Bool] {
        var results: [Bool] = []
        
        for predicate in predicates {
            results.append(resolvePredicate(predicates: predicate))
        }
        
        return results
    }
    
    private func resolvePredicate(predicates: [Any]) -> Bool {
        var solvedPredicates: [Any] = []
        
        if predicates.contains(where: { element in
            element as? DBToken == .dbOpenBracket
        }) {
            var balance = 0
            var startIndex = -1

            for i in 0..<predicates.count {
                if predicates[i] as? DBToken == .dbOpenBracket {
                    if balance == 0 {
                        startIndex = i + 1
                    }
                    balance += 1
                } else if predicates[i] as? DBToken == .dbCloseBracket {
                    balance -= 1
                    if balance == 0 {
                        solvedPredicates.append(resolvePredicate(predicates: Array(predicates[startIndex..<i])))
                    }
                } else if balance == 0 {
                    solvedPredicates.append(predicates[i])
                }
            }
            
            return resolvePredicate(predicates: solvedPredicates)
        } else if predicates.contains(where: { element in
            element as? DBToken == .dbNot
        }) {
            var skipIndex = -1
            
            for i in 0..<predicates.count {
                if predicates[i] as? DBToken == .dbNot,
                   let value = predicates[i + 1] as? Bool {
                    solvedPredicates.append(!value)
                    skipIndex = i+1
                } else if i != skipIndex {
                    solvedPredicates.append(predicates[i])
                } else {
                    skipIndex = -1
                }
            }
            
            return resolvePredicate(predicates: solvedPredicates)
        } else if predicates.contains(where: { element in
            element as? DBToken == .dbAnd
        }) {
            var skipIndex = -1
            
            for i in 0..<predicates.count {
                if predicates[i] as? DBToken == .dbAnd,
                   let leftValue = predicates[i - 1] as? Bool,
                   let rightValue = predicates[i + 1] as? Bool {
                    solvedPredicates = ArrayHelpers.removeLastElement(array: solvedPredicates)
                    solvedPredicates.append(leftValue == true && rightValue == true)
                    skipIndex = i + 1
                } else if i != skipIndex {
                    solvedPredicates.append(predicates[i])
                } else {
                    skipIndex = -1
                }
            }
            
            return resolvePredicate(predicates: solvedPredicates)
        } else if predicates.contains(where: { element in
            element as? DBToken == .dbOr
        }) {
            return predicates.contains { element in
                element as? Bool == true
            }
        } else if predicates.count == 1 {
            guard let value = predicates[0] as? Bool else {
                print("Error")
                return false
            }
            
            return value
        }
        
        return false
    }
}
