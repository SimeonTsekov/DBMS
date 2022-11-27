//
//  CommandParser.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

class CommandParser {
    func assignTypes(tokens: [String]) -> [Any] {
        var assigned: [Any] = []

        for token in tokens {
            if let keyword = DBKeyword(rawValue: token) {
                assigned.append(keyword)
            } else if let dbToken = DBToken(rawValue: token) {
                assigned.append(dbToken)
            } else if let dbType = DBType(rawValue: token) {
                assigned.append(dbType)
            } else if StringHelpers.stringContainsCharacter(string: token, character: "("){
                var internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: "(")
                internalArguments[internalArguments.count - 1] = StringHelpers.removeLastCharacter(string: internalArguments[internalArguments.count - 1])
                assigned.append(contentsOf: assignTypes(tokens: internalArguments))
                assigned.append(DBToken.dbCloseBracket)
            } else if StringHelpers.stringContainsCharacter(string: token, character: ","){
                let internalArguments = StringHelpers.splitStringByCharacter(string: token, character: ",")
                let internalAssigned = assignTypes(tokens: internalArguments)
                assigned.append(contentsOf: internalAssigned)
            } else if StringHelpers.stringContainsCharacter(string: token, character: ":"){
                let internalArguments = StringHelpers.splitStringByCharacterAndKeepIt(string: token, character: ":")
                let internalAssigned = assignTypes(tokens: internalArguments)
                assigned.append(contentsOf: internalAssigned)
            } else {
                assigned.append(token)
            }
        }

        return assigned
    }
}
