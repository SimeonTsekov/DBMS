//
//  String+Identifiable.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 22.01.23.
//

import Foundation

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}
