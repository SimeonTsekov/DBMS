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
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

        var varName: String = ""
        var varType: DBType = .dbString
        var varDefaultValue: String = ""
        var lastObject: Any

        guard let subject = tokens[0] as? String else {
            print("Couldn't parse object as String")
            return
        }
        
        query.subject = subject
        query.objects = []
        var objects: [Any] = ArrayHelpers.removeFirstElement(array: tokens)
        
        guard objects[0] as? DBToken == .dbOpenBracket else {
            print("No opening bracket for table creation")
            return
        }
        lastObject = objects[0]
        objects = ArrayHelpers.removeFirstElement(array: objects)
        
        if objects[0] as? DBToken == .dbCloseBracket ||
           objects[0] as? DBToken == .dbComma {
            print("Can't create an empty table")
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
                    print("Syntax error")
                    return
                }
                varName = object
            }
            
            // Type descriptor - :
            if object as? DBToken == .dbTypeDescriptor,
               !(lastObject is String) {
                print("Types descriptors can only appear after a variable name")
                return
            }
            
            // Type
            if let object = object as? DBType  {
                if lastObject as? DBToken != .dbTypeDescriptor {
                    print("Types can only appear after type descriptors")
                    return
                }
                varType = object
            }

            // Default keyword
            if object as? DBKeyword == .dbDefault,
               !(lastObject is DBType) {
                print("Default values can only appear after valid variables")
                return
            }

            // Comma
            if object as? DBToken == .dbComma{
                if !(lastObject is DBType) && !(lastObject is String) {
                    print("Commas can only appear after types and default values")
                    return
                }

                query.objects?.append(Field(name: varName, type: varType, defaultValue: varDefaultValue == "" ? nil : varDefaultValue))
                varDefaultValue = ""
            }

            // Closing bracket
            if object as? DBToken == .dbCloseBracket {
                if !(lastObject is DBType) && !(lastObject is String) {
                    print("Closing brackets can only appear after types and default values")
                    return
                }

                query.objects?.append(Field(name: varName, type: varType, defaultValue: varDefaultValue == "" ? nil : varDefaultValue))
                break
            }
            
            lastObject = object
        }
        
        guard objects.last as? DBToken == .dbCloseBracket else {
            print("Can't contain anything after closing bracket")
            return
        }
    }
    
    func parseDrop(with tokens: [Any], for query: Query) {
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

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
                    print("Commas can only appear after names")
                    return
                }
            }
            
            lastToken = token
        }
        
        guard lastToken as? DBToken != .dbComma else {
            print("Cannot end drop statement on a comma")
            return
        }
        
        query.subjects = subjects
    }

    func parseInfo(with tokens: [Any], for query: Query) {
        guard tokens.count == 1 else {
            print("Parse can only have 1 argument")
            return
        }
        
        guard let tableName = tokens[0] as? String else {
            print("Must only provide a table name")
            return
        }

        query.subject = tableName
    }
    
    func parseInsert(with tokens: [Any], for query: Query) {
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

        var parsingMode: DBParseMode?
        var table = TableInsertScehma(name: "", fields: [])
        var value = TableValue(values: [])
        var lastObject: Any

        guard let keyword = tokens[0] as? DBKeyword,
              keyword == .dbInto else {
            print("Missing an INTO keyword")
            return
        }

        query.subjects = []
        lastObject = keyword
        let queryTokens = ArrayHelpers.removeFirstElement(array: tokens)
        
        for token in queryTokens {
            // Table name
            if let subject = token as? String,
               lastObject as? DBKeyword == .dbInto {
                table.name = subject
                parsingMode = .dbTable
            }

            // Open bracket
            if token as? DBToken == .dbOpenBracket,
               !(lastObject is String) && !(lastObject is DBToken) && !(lastObject is DBKeyword){
                print("Opening bracket can only appear after table name and as a value opener")
                return
            }

            // Field name
            if let val = token as? String,
               lastObject as? DBKeyword != .dbInto {
                if lastObject as? DBToken != .dbComma &&
                    lastObject as? DBToken != .dbOpenBracket {
                    print("Syntax error")
                    return
                }
                switch parsingMode {
                case .dbTable:
                    table.fields.append(val)
                case .dbValue:
                    value.values.append(val)
                case .none:
                    print("No query parsing mode available")
                    return
                }
            }
            
            // Comma
            if token as? DBToken == .dbComma,
               !(lastObject is String) && lastObject as? DBToken != .dbCloseBracket {
                print("Commas can only appear after field names and values")
                return
            }

            // Close bracket
            if token as? DBToken == .dbCloseBracket{
               if !(lastObject is String) {
                   print("Wrong table schema syntax")
                   return
               }

                switch parsingMode {
                case .dbTable:
                    query.object = table
                case .dbValue:
                    query.subjects?.append(value)
                    value.values = []
                case .none:
                    print("No query parsing mode available")
                    return
                }
            }

            // VALUES keyword
            if token as? DBKeyword == .dbValues {
                if lastObject as? DBToken != .dbCloseBracket {
                    print("VALUES keyword can only appear after closing brackets")
                    return
                }
                parsingMode = .dbValue
            }

            lastObject = token
        }
    }
    
    func parseSelect(with tokens: [Any], for query: Query) {
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

        var lastSubject: Any?

        query.subjects = []
        query.predicates = []
        
        for token in tokens {
            // DISTINCT
            if token as? DBKeyword == .dbDistinct,
               lastSubject == nil  {
                query.distinctSelection = true
            }

            // Table or Field name
            if let subject = token as? String,
               !((lastSubject as? DBKeyword) == .dbWhere) {
                if lastSubject as? DBKeyword == .dbFrom {
                    query.object = subject
                } else if lastSubject as? DBToken == .dbComma || lastSubject as? DBKeyword == .dbDistinct || lastSubject == nil {
                    query.subjects?.append(subject)
                } else if lastSubject as? DBKeyword == .dbOrderBy {
                    query.orderFactor = subject
                } else {
                    print("Syntax error")
                    return
                }
            }
            
            // Comma
            if token as? DBToken == .dbComma,
               !(lastSubject is String) {
                print("Commas can only appear after field names")
                return
            }

            // From
            if token as? DBKeyword == .dbFrom,
               !(lastSubject is String) {
                print("Please provide fields for selection")
                return
            }
            
            if token as? DBKeyword == .dbOrderBy {
                lastSubject = token
            } else if lastSubject as? DBKeyword == .dbWhere {
                query.predicates?.append(token)
            } else {
                lastSubject = token
            }
        }
    }
    
    func parseDelete(with tokens: [Any], for query: Query) {
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

        var lastSubject: Any

        guard let keyword = tokens[0] as? DBKeyword,
              keyword == .dbFrom else {
            print("Missing an FROM keyword")
            return
        }

        query.subjects = []
        query.predicates = []
        lastSubject = keyword
        let queryTokens = ArrayHelpers.removeFirstElement(array: tokens)
        
        for token in queryTokens {
            // Table Name
            if token is String,
               lastSubject as? DBKeyword == .dbFrom {
                query.object = token
            }
            
            if lastSubject as? DBKeyword == .dbWhere {
                query.predicates?.append(token)
            } else {
                lastSubject = token
            }
        }
        return
    }
    
    func parseCreateIndex(with tokens: [Any], for query: Query) {
        guard !tokens.isEmpty else {
            print("Must provide arguments")
            return
        }

        var lastObject: Any? = nil
        query.objects = []
        
        for token in tokens {
            // Index name
            if let subject = token as? String,
               lastObject == nil {
                query.subject = subject
            }

            // Open bracket
            if token as? DBToken == .dbOpenBracket,
               !(lastObject is String) {
                print("Opening bracket can only appear after table name")
                return
            }

            // Field name
            if let val = token as? String,
                lastObject != nil {
                query.objects?.append(val)
            }

            // Close bracket
            if token as? DBToken == .dbCloseBracket,
               !(lastObject is String) {
                print("Wrong table schema syntax")
                return
            }

            lastObject = token
        }
    }
}
