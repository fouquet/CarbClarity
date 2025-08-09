//
//  CarbClarityTestingSetup.swift
//  CarbClarity
//
//  Created by René Fouquet on 15.07.25.
//

import SwiftUI
import SwiftData

struct CarbClarityTestingSetup {
    static func createTestModelContainer() -> ModelContainer {
        let schema = Schema([
            CarbEntry.self,
        ])

        let shouldResetSettings = ProcessInfo.processInfo.arguments.contains("--reset-settings")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            if shouldResetSettings {
                resetUserDefaults()
                clearAllData(in: container)
            }
            if ProcessInfo.processInfo.arguments.contains("--enable-food-lookup") {
                UserDefaults.standard.set(true, forKey: "lookupEnabled")
            }

            if ProcessInfo.processInfo.arguments.contains("--test-api-key") {
                UserDefaults.standard.set("test-api-key-for-ui-testing", forKey: "lookupAPIKey")
            }
            
            if ProcessInfo.processInfo.arguments.contains("--enable-quick-add-buttons") {
                UserDefaults.standard.set(true, forKey: "quickAddButtonsEnabled")
            }
            
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    private static func resetUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "carbLimit")
        defaults.removeObject(forKey: "cautionLimit")
        defaults.removeObject(forKey: "warnLimitEnabled")
        defaults.removeObject(forKey: "cautionLimitEnabled")
        defaults.removeObject(forKey: "lookupEnabled")
        defaults.removeObject(forKey: "lookupAPIKey")
        defaults.removeObject(forKey: "quickAddButtonsEnabled")
        defaults.synchronize()
    }

    private static func clearAllData(in container: ModelContainer) {
        do {
            let modelContext = ModelContext(container)

            let descriptor = FetchDescriptor<CarbEntry>()
            let existingEntries = try modelContext.fetch(descriptor)

            for entry in existingEntries {
                modelContext.delete(entry)
            }

            try modelContext.save()
        } catch {
            fatalError("Error clearing all data: \(error)")
        }
    }
    

}
