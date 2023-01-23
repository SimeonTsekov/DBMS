//
//  Binding+Unwrapped.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 23.01.23.
//

import Foundation
import SwiftUI

extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
