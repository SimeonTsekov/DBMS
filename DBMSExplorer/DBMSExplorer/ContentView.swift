//
//  ContentView.swift
//  DBMSExplorer
//
//  Created by Simeon Tsekov on 21.01.23.
//

import SwiftUI
import DBMSKit

enum ScreenTag: String {
    case tables = "Tables"
    case console = "Console"
}

struct ContentView: View {
    @State var currentTabTag: ScreenTag = .tables
    let queryManager = QueryManager()
    
    var body: some View {
        TabView(selection: Binding<ScreenTag>(get: { currentTabTag },
                                              set: { currentTabTag = $0 })) {
            TablesScreen(title: currentTabTag.rawValue, tablesViewModel: TablesViewModel(manager: queryManager))
                .tabItem {
                    Image(systemName: "tray.2.fill")
                    Text(ScreenTag.tables.rawValue)
                }
                .tag(ScreenTag.tables)
            ConsoleScreen(title: currentTabTag.rawValue, consoleViewModel: ConsoleViewModel(manager: queryManager))
                .tabItem {
                    Image(systemName: "terminal.fill")
                    Text(ScreenTag.console.rawValue)
                }
                .tag(ScreenTag.console)
        }
        .environmentObject(queryManager)
    }
}
