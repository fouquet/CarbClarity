//
//  CarbClarityApp.swift
//  CarbClarity
//
//  Created by René Fouquet on 07.06.24.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct CarbClarityApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CarbEntry.self,
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, groupContainer: .identifier(AppSettings.appGroupIdentifier))
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        let container = sharedModelContainer
        Task { @MainActor in
            AppDependencyManager.shared.setModelContainer(container)
        }
        
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
    
}
