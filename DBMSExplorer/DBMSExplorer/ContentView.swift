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

// INSERT INTO Sample2 (Id, Name, BirthDate) VALUES (1, Ivan, 10-07-2002), (2, Dragan, 29-03-2006), (3, Isidor, 25-11-1974), (4, Zyumbyul, 16-07-1975)
// SELECT Name, BirthDate FROM Sample2 WHERE Id > 2 AND BirthDate >= 25.11.1974
// SELECT Id, Name FROM Sample2 WHERE Name = Isidor
// DELETE FROM Sample2 WHERE Id = 3
// DELETE FROM Sample2 WHERE Id = 4 OR Id = 2 OR Id = 1
// CREATEINDEX Sample2Id ON Sample2(Id)
// SELECT Id, Name FROM Sample2 WHERE Id = 1
// DROPINDEX Sample2Id
