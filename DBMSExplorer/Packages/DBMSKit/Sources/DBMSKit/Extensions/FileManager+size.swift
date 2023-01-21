//
//  FileManager+size.swift
//  DBMSKit
//
//  Created by Simeon Tsekov on 12.12.22.
//

import Foundation

extension FileManager {
    func sizeOfFile(atPath path: String) -> Int64? {
        guard let attrs = try? attributesOfItem(atPath: path) else {
            return nil
        }

        return attrs[.size] as? Int64
    }
}
