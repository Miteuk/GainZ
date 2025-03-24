//
//  GainZApp.swift
//  GainZ
//
//  Created by Tim Kue on 3/23/25.
//

import SwiftUI

@main
struct GainZApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext,
                             persistenceController.container.viewContext)
        }
    }
}
