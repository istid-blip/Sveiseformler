//
//  SveiseformlerApp.swift
//  Sveiseformler
//
//  Created by Frode Halrynjo on 05/01/2026.
//

import SwiftUI
import CoreData

@main
struct SveiseformlerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
