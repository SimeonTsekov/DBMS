//
//  ContentView.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI

enum ScreenTag: String {
    case tables = "Tables"
    case indexes = "Indexes"
    case console = "Console"
}

struct ContentView: View {
    @State var currentTabTag: ScreenTag = .tables

    var body: some View {
        NavigationView() {
            TabView(selection: Binding<ScreenTag>(get: { currentTabTag },
                                                  set: { currentTabTag = $0 })) {
                TablesScreen(title: currentTabTag.rawValue)
                    .tabItem {
                        Image(systemName: "tray.2.fill")
                        Text(ScreenTag.tables.rawValue)
                    }
                    .tag(ScreenTag.tables)
                Text("Second Tab")
                    .tabItem {
                        Image(systemName: "menucard.fill")
                        Text(ScreenTag.indexes.rawValue)
                    }
                    .tag(ScreenTag.indexes)
                Text("Third Tab")
                    .tabItem {
                        Image(systemName: "terminal.fill")
                        Text(ScreenTag.console.rawValue)
                    }
                    .tag(ScreenTag.console)
            }
            .toolbar {
                if currentTabTag == .tables || currentTabTag == .indexes {
                    Button {
                        switch currentTabTag {
                        case .tables:
                            print("Add Table")
                        case .indexes:
                            print("Add Index")
                        case .console:
                            break
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            
        }
    }
}
