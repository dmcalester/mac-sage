//
//  macSageApp.swift
//  macSage
//
//  Created by Duncan McAlester on 11/7/24.
//

import SwiftUI

@main
struct macSageApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
