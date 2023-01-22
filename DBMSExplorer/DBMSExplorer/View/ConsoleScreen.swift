//
//  ConsoleScreen.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI

struct ConsoleScreen: View {
    @ObservedObject private var consoleViewModel: ConsoleViewModel
    var title: String
    
    init(title: String, consoleViewModel: ConsoleViewModel) {
        self.consoleViewModel = consoleViewModel
        self.title = title
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List(consoleViewModel.output) { output in
                    Text(output)
                }.safeAreaInset(edge: .bottom) {
                    HStack {
                        TextField("Enter your query", text: $consoleViewModel.query)
                            .textFieldStyle(.roundedBorder)
                            .padding([.top, .leading, .bottom])
                        Button {
                            consoleViewModel.sendQuery()
                        } label: {
                            Image(systemName: "paperplane.fill")
                        }.padding([.top, .trailing, .bottom])
                    }.background(.ultraThinMaterial)
                }
            }
            .navigationTitle(title)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
