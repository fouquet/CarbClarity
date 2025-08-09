//
//  CarbClarityWatchApp.swift
//  CarbClarityWatch
//
//  Created by René Fouquet on 18.07.25.
//

import SwiftUI
import SwiftData
import ClockKit

@main
struct CarbClarityWatchApp: App {
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
        CLKComplicationServer.sharedInstance().reloadComplicationDescriptors()
        
        _ = WatchConnectivityManager.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchMainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
