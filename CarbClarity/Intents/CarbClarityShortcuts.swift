//
//  CarbClarityShortcuts.swift
//  CarbClarity
//
//  Created by René Fouquet on 18.07.25.
//

import AppIntents

struct CarbClarityShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [AppShortcut(
            intent: LogCarbsIntent(),
            phrases: [
                "Log carbs in \(.applicationName)",
                "Add carbs to \(.applicationName)",
                "Log carbs in \(.applicationName)",
                "Add carbs to \(.applicationName)"
            ],
            shortTitle: "Log Carbs",
            systemImageName: "plus.circle"
        ),
        
        AppShortcut(
            intent: GetDailySummaryIntent(),
            phrases: [
                "Check my carbs in \(.applicationName)",
                "Get my carb summary from \(.applicationName)",
                "How many carbs today in \(.applicationName)",
                "Show my daily carbs in \(.applicationName)"
            ],
            shortTitle: "Daily Summary",
            systemImageName: "chart.bar"
        )]
    }
}
