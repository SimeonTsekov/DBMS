//
//  StringHelpers.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

class StringHelpers {
    static func splitStringByCharacter(string: String, character: Character) -> [String] {
        var word = ""
        var tokens: [String] = []
        
        for char in string {
            if char == character {
                tokens.append(word)
                word = ""
            } else {
                word.append(char)
            }
        }
        
        tokens.append(word)
        return tokens
    }

    static func splitStringByCharacterAndKeepIt(string: String, character: Character) -> [String] {
        var word = ""
        var tokens: [String] = []
        
        for char in string {
            if char == character {
                tokens.append(word)
                tokens.append(String(character))
                word = ""
            } else {
                word.append(char)
            }
        }
        
        if word != "" {
            tokens.append(word)
        }
        if tokens[0] == "" {
            tokens = ArrayHelpers.removeFirstElement(array: tokens)
        }
        return tokens
    }

    static func stringContainsCharacter(string: String, character: Character) -> Bool {
        for char in string {
            if char == character {
                return true
            }
        }
        
        return false
    }

    static func stringContainsString(base: String, searched: String) -> Bool {
        if searched.isEmpty {
            return false
        }
        
        let baseCharacters = Array(base)
        let searchedCharacters = Array(searched)
        var matched = 0
        
        for i in 0..<baseCharacters.count {
            if baseCharacters[i] != searchedCharacters[matched] {
                matched = 0
            } else {
                matched += 1
                if matched == searched.count {
                    return true
                }
            }
        }
        
        return false
    }

    static func removeLastCharacter(string: String) -> String {
        var characters: [Character] = []
        var newString = ""
        
        for char in string {
            characters.append(char)
        }
        
        for element in ArrayHelpers.removeLastElement(array: characters) {
            newString.append(element)
        }
        
        return newString
    }

    static func clearStringWhitespaces(string: String) -> String {
        var newString = ""
        var lastChar: Character = "l"
        
        for char in string {
            if char == " " && lastChar == " " {
                continue
            }
            
            newString.append(char)
            lastChar = char
        }
        
        if newString.last == " " {
            newString = removeLastCharacter(string: newString)
        }
        
        return newString
    }

    static func removeCharactersFromEnd(string: String, count: Int) -> String {
        let chars = Array(string)
        var newString = ""

        for i in 0..<(chars.count - count) {
            newString.append(chars[i])
        }

        return newString
    }
    
    static func sdbmHash(str: String) -> UInt16 {
        var hash: UInt16 = 0
        let characters = Array(str)

        for i in 0..<str.count {
            hash = UInt16(characters[i].asciiValue ?? 0) &+ (hash << 6) &+ (hash << 16) &- hash
        }

        return hash
    }
}
