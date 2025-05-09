//
//  GainzApp.swift
//  Gainz
//
//  Created by Alex Nguyen on 5/8/25.
//

import SwiftUI

@main
struct GainzApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
