//
//  ParsingModels.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

enum DBKeyword: String {
    case dbCreate = "CREATE"
    case dbDefault = "DEFAULT"
    case dbDrop = "DROP"
    case dbList = "LIST"
    case dbInfo = "INFO"
    case dbSelect = "SELECT"
    case dbFrom = "FROM"
    case dbWhere = "WHERE"
    case dbOrderBy = "ORDER BY"
    case dbDistinct = "DISTINCT"
    case dbDelete = "DELETE"
    case dbInsert = "INSERT"
    case dbInto = "INTO"
    case dbValues = "VALUES"
    case dbCreateIndex = "CREATE INDEX"
    case dbDropIndex = "DROP INDEX"
}

enum DBToken: String {
    case dbAnd = "AND"
    case dbOr = "OR"
    case dbNot = "NOT"
    case dbOpenBracket = "("
    case dbCloseBracket = ")"
    case dbEqual = "="
    case dbLessOrEqual = "<="
    case dbGreaterOrEqual = ">="
    case dbNotEqual = "!="
    case dbLesser = "<"
    case dbGreater = ">"
    case dbTypeDescriptor = ":"
    case dbComma = ","
    
    var isArithmeticOperator: Bool {
        switch self {
        case .dbAnd, .dbOr, .dbNot, .dbOpenBracket, .dbCloseBracket, .dbTypeDescriptor, .dbComma:
            return false
        case .dbEqual, .dbLessOrEqual, .dbGreaterOrEqual, .dbNotEqual, .dbLesser, .dbGreater:
            return true
        }
    }
}

enum DBType: String {
    case dbInt = "int"
    case dbDate = "date"
    case dbString = "string"
}

enum DBParseMode {
    case dbTable
    case dbValue
}
