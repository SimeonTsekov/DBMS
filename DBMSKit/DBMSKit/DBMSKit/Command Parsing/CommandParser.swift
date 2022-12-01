//
//  CommandParser.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

class CommandParser {
    func tokenize(tokens: [String]) -> [Any] {
        var assigned: [Any] = []

        for token in tokens {
            if let keyword = DBKeyword(rawValue: token) {
                assigned.append(keyword)
            } else if let dbToken = DBToken(rawValue: token) {
                assigned.append(dbToken)
            } else if let dbType = DBType(rawValue: token) {
                assigned.append(dbType)
            } else if StringHelpers.stringContainsCharacter(string: token, character: "(") {
                let internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: "(")
                assigned.append(contentsOf: tokenize(tokens: internalArguments))
            } else if StringHelpers.stringContainsCharacter(string: token, character: ",") {
                let internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: ",")
                assigned.append(contentsOf: tokenize(tokens: internalArguments))
            } else if StringHelpers.stringContainsCharacter(string: token, character: ":") {
                let internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: ":")
                assigned.append(contentsOf: tokenize(tokens: internalArguments))
            } else if StringHelpers.stringContainsCharacter(string: token, character: ")") {
                let internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: ")")
                assigned.append(contentsOf: tokenize(tokens: internalArguments))
            } else {
                assigned.append(token)
            }
        }

        return assigned
    }

    func parseCreate(with tokens: [Any], for query: Query) {
        var varName: String = ""
        var varType: DBType = .dbString
        var varDefaultValue: String = ""
        var lastObject: Any

        guard let subject = tokens[0] as? String else {
            assertionFailure("Couldn't parse object as String!")
            return
        }
        
        query.subject = subject
        query.objects = []
        var objects: [Any] = ArrayHelpers.removeFirstElement(array: tokens)
        
        guard objects[0] as? DBToken == .dbOpenBracket else {
            assertionFailure("No opening bracket for table creation")
            return
        }
        lastObject = objects[0]
        objects = ArrayHelpers.removeFirstElement(array: objects)
        
        if objects[0] as? DBToken == .dbCloseBracket ||
           objects[0] as? DBToken == .dbComma {
            assertionFailure("Can't create an empty table")
            return
        }
        
        for object in objects {
            // Default value
            if let object = object as? String,
               lastObject as? DBKeyword == .dbDefault {
                varDefaultValue = object
                lastObject = object
                continue
            }
            
            // Variable Name
            if let object = object as? String {
                if lastObject as? DBToken != .dbComma &&
                    lastObject as? DBToken != .dbOpenBracket &&
                    lastObject as? DBKeyword != .dbDefault {
                    assertionFailure("Syntax error")
                    return
                }
                varName = object
            }
            
            // Type descriptor - :
            if object as? DBToken == .dbTypeDescriptor,
               !(lastObject is String) {
                assertionFailure("Types descriptors can only appear after a variable name")
                return
            }
            
            // Type
            if let object = object as? DBType  {
                if lastObject as? DBToken != .dbTypeDescriptor {
                    assertionFailure("Types can only appear after type descriptors")
                    return
                }
                varType = object
            }

            // Default keyword
            if object as? DBKeyword == .dbDefault,
               !(lastObject is DBType) {
                assertionFailure("Default values can only appear after valid variables")
                return
            }

            // Comma
            if object as? DBToken == .dbComma{
                if !(lastObject is DBType) && !(lastObject is String) {
                    assertionFailure("Commas can only appear after types and default values")
                    return
                }

                query.objects?.append(Field(name: varName, type: varType, defaultValue: varDefaultValue == "" ? nil : varDefaultValue))
                varDefaultValue = ""
            }

            // Closing bracket
            if object as? DBToken == .dbCloseBracket {
                if !(lastObject is DBType) && !(lastObject is String) {
                    assertionFailure("Closing brackets can only appear after types and default values")
                    return
                }

                query.objects?.append(Field(name: varName, type: varType, defaultValue: varDefaultValue == "" ? nil : varDefaultValue))
                break
            }
            
            lastObject = object
        }
        
        guard objects.last as? DBToken == .dbCloseBracket else {
            assertionFailure("Can't contain anything after closing bracket")
            return
        }
    }
    
    func parseDrop(with tokens: [Any], for query: Query) {
        var lastToken: Any = tokens[0]
        var subjects: [String] = []

        for token in tokens {
            // Variable Name
            if let subject = token as? String {
                subjects.append(subject)
            }
            
            // Comma
            if token as? DBToken == .dbComma{
                if !(lastToken is String) {
                    assertionFailure("Commas can only appear after names")
                    return
                }
            }
            
            lastToken = token
        }
        
        guard lastToken as? DBToken != .dbComma else {
            assertionFailure("Cannot end drop statement on a comma")
            return
        }
        
        query.subjects = subjects
    }
}
