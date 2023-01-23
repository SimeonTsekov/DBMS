//
//  FieldView.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 23.01.23.
//

import SwiftUI
import DBMSKit

struct FieldView: View {
    @Binding var field: Field
    
    var body: some View {
        HStack {
            TextField("Field Name", text: $field.name)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
            TextField("Default Value", text: $field.defaultValue.toUnwrapped(defaultValue: ""))
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
            Picker("", selection: $field.type) {
                ForEach(DBType.allCases, id: \.rawValue) { value in
                    Text(value.rawValue.capitalized)
                        .tag(value)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
