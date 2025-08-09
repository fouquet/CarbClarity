//
//  MockDataGenerator.swift
//  CarbClarity
//
//  Created by René Fouquet on 17.07.25.
//

import Foundation
import SwiftData

/// Generates mock carb entry data for testing and development purposes
/// Should not be included in production code. Make sure to remove the target membership,
/// if present.
@MainActor
class MockDataGenerator {
    
    /// Generates mock data for the specified number of days backwards from today
    /// - Parameters:
    ///   - modelContext: The SwiftData model context to insert data into
    ///   - days: Number of days to generate data for (default: 35)
    ///   - clearExisting: Whether to clear existing data first (default: true)
    static func generateMockData(
        modelContext: ModelContext,
        days: Int = 35,
        clearExisting: Bool = true
    ) {
        if clearExisting {
            clearAllData(modelContext: modelContext)
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        for dayOffset in 0..<days {
            guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else {
                continue
            }
            
            let entryCount = Int.random(in: 3...5)
            
            for _ in 0..<entryCount {
                let carbValue = [0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0].randomElement()!
                let randomHour = Int.random(in: 6...22)
                let randomMinute = Int.random(in: 0...59)
                
                guard let entryTime = calendar.date(
                    bySettingHour: randomHour,
                    minute: randomMinute,
                    second: 0,
                    of: targetDate
                ) else {
                    continue
                }
                
                let entry = CarbEntry(timestamp: entryTime, value: carbValue)
                modelContext.insert(entry)
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Mock data generated: \(days) days with random entries")
        } catch {
            print("❌ Error saving mock data: \(error)")
        }
    }
    
    /// Clears all existing carb entries from the database
    /// - Parameter modelContext: The SwiftData model context
    static func clearAllData(modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<CarbEntry>()
            let existingEntries = try modelContext.fetch(descriptor)
            
            for entry in existingEntries {
                modelContext.delete(entry)
            }
            
            try modelContext.save()
            print("✅ Cleared \(existingEntries.count) existing entries")
        } catch {
            print("❌ Error clearing existing data: \(error)")
        }
    }
    
    /// Generates mock data with specific patterns for testing different scenarios
    /// - Parameters:
    ///   - modelContext: The SwiftData model context
    ///   - scenario: The test scenario to generate
    static func generateTestScenario(
        modelContext: ModelContext,
        scenario: TestScenario
    ) {
        clearAllData(modelContext: modelContext)
        
        let calendar = Calendar.current
        let now = Date()
        
        switch scenario {
        case .increasingTrend:
            // Generate data with increasing carb intake over time
            for dayOffset in 0..<35 {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let entryCount = Int.random(in: 3...5)
                
                for _ in 0..<entryCount {
                    // Create a realistic increasing trend using common values
                    let trendMultiplier = Double(35 - dayOffset) / 35.0 // 0.0 to 1.0
                    let possibleValues = [0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
                    let weightedIndex = min(Int(trendMultiplier * Double(possibleValues.count - 1)), possibleValues.count - 1)
                    let carbValue = possibleValues[max(0, weightedIndex + Int.random(in: -1...1))]
                    let randomHour = Int.random(in: 7...21)
                    let randomMinute = Int.random(in: 0...59)
                    
                    guard let entryTime = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: targetDate) else { continue }
                    
                    let entry = CarbEntry(timestamp: entryTime, value: max(1.0, carbValue))
                    modelContext.insert(entry)
                }
            }
            
        case .decreasingTrend:
            // Generate data with decreasing carb intake over time
            for dayOffset in 0..<35 {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let entryCount = Int.random(in: 3...5)
                
                for _ in 0..<entryCount {
                    // Create a realistic decreasing trend using common values
                    let trendMultiplier = 1.0 - (Double(35 - dayOffset) / 35.0) // 1.0 to 0.0 (decreasing)
                    let possibleValues = [0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
                    let weightedIndex = min(Int(trendMultiplier * Double(possibleValues.count - 1)), possibleValues.count - 1)
                    let carbValue = possibleValues[max(0, weightedIndex + Int.random(in: -1...1))]
                    let randomHour = Int.random(in: 7...21)
                    let randomMinute = Int.random(in: 0...59)
                    
                    guard let entryTime = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: targetDate) else { continue }
                    
                    let entry = CarbEntry(timestamp: entryTime, value: carbValue)
                    modelContext.insert(entry)
                }
            }
            
        case .highVariability:
            // Generate data with high day-to-day variability
            for dayOffset in 0..<35 {
                guard let targetDate = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
                
                let entryCount = Int.random(in: 2...7) // More variable entry count
                
                for _ in 0..<entryCount {
                    // Create high variability using realistic single-digit values with weighted randomness
                    let possibleValues = [0.1, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 10.0]
                    let carbValue = possibleValues.randomElement()!
                    let randomHour = Int.random(in: 6...23)
                    let randomMinute = Int.random(in: 0...59)
                    
                    guard let entryTime = calendar.date(bySettingHour: randomHour, minute: randomMinute, second: 0, of: targetDate) else { continue }
                    
                    let entry = CarbEntry(timestamp: entryTime, value: carbValue)
                    modelContext.insert(entry)
                }
            }
        }
        
        do {
            try modelContext.save()
            print("✅ Test scenario '\(scenario)' generated")
        } catch {
            print("❌ Error saving test scenario data: \(error)")
        }
    }
}

/// Test scenarios for generating different patterns of mock data
enum TestScenario: String, CaseIterable {
    case increasingTrend = "Increasing Trend"
    case decreasingTrend = "Decreasing Trend"
    case highVariability = "High Variability"
}
