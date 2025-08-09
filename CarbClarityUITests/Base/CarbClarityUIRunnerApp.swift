//
//  CarbClarityUIRunnerApp.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 15.07.25.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct CarbClarityUIRunnerApp: App {
    var sharedModelContainer: ModelContainer = {
        return CarbClarityTestingSetup.createTestModelContainer()
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.lookupAPIFactory) {
                    USDAAPIMock()
                }
        }
        .modelContainer(sharedModelContainer)
    }

}
