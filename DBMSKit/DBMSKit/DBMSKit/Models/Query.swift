//
//  Query.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 28.11.22.
//

import Foundation

class Query {
    let method: DBKeyword
    var subject: Any?
    var subjects: [Any]?
    var object: Any?
    var objects: [Any]?
    
    init(method: DBKeyword) {
        self.method = method
    }
}
