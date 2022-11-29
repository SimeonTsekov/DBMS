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
}
