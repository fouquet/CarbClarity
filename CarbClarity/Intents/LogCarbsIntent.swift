//
//  LogCarbsIntent.swift
//  CarbClarity
//
//  Created by René Fouquet on 18.07.25.
//

import AppIntents
import SwiftData
import Foundation
import WidgetKit

struct LogCarbsIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Carbohydrates"
    static let description = IntentDescription("Log carbohydrate intake to CarbClarity")
    
    @Parameter(title: "Carb Amount", description: "Amount of carbohydrates in grams")
    var carbAmount: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$carbAmount) grams of carbs")
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let modelContainer = AppDependencyManager.shared.modelContainer else {
            throw IntentError.modelContainerNotAvailable
        }
        
        let context = ModelContext(modelContainer)
        let entry = CarbEntry(timestamp: Date(), value: carbAmount)
        context.insert(entry)
        
        do {
            try context.save()
            
            WidgetUpdateManager.requestWidgetUpdate()
            
            let message = "Logged \(carbAmount.formatted(.number.precision(.fractionLength(0...1)))) grams of carbs"
            return .result(dialog: IntentDialog(stringLiteral: message))
        } catch {
            throw IntentError.saveFailed
        }
    }
}

enum IntentError: Error, LocalizedError {
    case modelContainerNotAvailable
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .modelContainerNotAvailable:
            return "Unable to access data storage"
        case .saveFailed:
            return "Failed to save carb entry"
        }
    }
}
