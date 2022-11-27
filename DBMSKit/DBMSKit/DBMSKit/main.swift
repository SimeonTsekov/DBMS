//
//  main.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 27.11.22.
//

import Foundation

let manager = QueryManager()
print("Enter a query:")

while let input = readLine() {
    guard input != "quit" else {
        break
    }

    manager.handleQuery(query: input)
    
    print("Enter a query:")
}
