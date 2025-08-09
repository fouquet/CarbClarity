//
//  GetDailySummaryIntent.swift
//  CarbClarity
//
//  Created by René Fouquet on 18.07.25.
//

import AppIntents
import SwiftData
import Foundation

struct GetDailySummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Daily Carb Summary"
    static let description = IntentDescription("Get today's carbohydrate intake summary from CarbClarity")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let modelContainer = AppDependencyManager.shared.modelContainer else {
            throw IntentError.modelContainerNotAvailable
        }
        
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<CarbEntry>()
        
        do {
            let allEntries = try context.fetch(descriptor)
            let todaysEntries = allEntries.filter { Calendar.current.isDateInToday($0.timestamp) }
            let totalCarbs = todaysEntries.reduce(0) { $0 + $1.value }
            
            let carbLimit = AppSettings.carbLimit
            let cautionLimit = AppSettings.cautionLimit
            let warnLimitEnabled = AppSettings.warnLimitEnabled
            let cautionLimitEnabled = AppSettings.cautionLimitEnabled
            
            let remainingCarbs = max(0, carbLimit - totalCarbs)
            let entryCount = todaysEntries.count
            
            var message: String
            var statusMessage = ""
            
            if warnLimitEnabled && totalCarbs > carbLimit {
                let overAmount = totalCarbs - carbLimit
                statusMessage = " You're \(overAmount.formatted(.number.precision(.fractionLength(0...1)))) grams over your limit."
            } else if cautionLimitEnabled && totalCarbs > cautionLimit {
                statusMessage = " You're approaching your limit."
            } else if remainingCarbs > 0 {
                statusMessage = " You have \(remainingCarbs.formatted(.number.precision(.fractionLength(0...1)))) grams remaining."
            }
            
            if entryCount == 0 {
                message = "You haven't logged any carbs today."
            } else if entryCount == 1 {
                message = "Today you've consumed \(totalCarbs.formatted(.number.precision(.fractionLength(0...1)))) grams of carbs from 1 entry.\(statusMessage)"
            } else {
                message = "Today you've consumed \(totalCarbs.formatted(.number.precision(.fractionLength(0...1)))) grams of carbs from \(entryCount) entries.\(statusMessage)"
            }
            
            return .result(dialog: IntentDialog(stringLiteral: message))
        } catch {
            throw IntentError.saveFailed
        }
    }
}
