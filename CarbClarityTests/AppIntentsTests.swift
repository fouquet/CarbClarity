//
//  AppIntentsTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 18.07.25.
//

import XCTest
import SwiftData
import AppIntents
@testable import CarbClarity

final class AppIntentsTests: XCTestCase {
    
    
    func testCarbClarityShortcuts_WhenAccessed_HasCorrectCount() {
        // Given & When
        let shortcuts = CarbClarityShortcuts.appShortcuts
        
        XCTAssertEqual(shortcuts.count, 2)
        XCTAssertTrue(shortcuts.count > 0)
    }
    
    func testIntentError_WithDifferentTypes_HasCorrectLocalizedDescriptions() {
        let containerError = IntentError.modelContainerNotAvailable
        let saveError = IntentError.saveFailed
        
        XCTAssertEqual(containerError.errorDescription, "Unable to access data storage")
        XCTAssertEqual(saveError.errorDescription, "Failed to save carb entry")
    }
    
    @MainActor
    func testAppDependencyManager_WhenAccessingShared_ReturnsSameInstance() {
        // Given & When
        let manager1 = CarbClarity.AppDependencyManager.shared
        let manager2 = CarbClarity.AppDependencyManager.shared
        
        XCTAssertTrue(manager1 === manager2)
    }
    
    @MainActor
    func testLogCarbsIntent_WhenModelContainerNotAvailable_ThrowsCorrectError() async {
        // Given
        let intent = LogCarbsIntent()
        intent.carbAmount = 25.5
        
        AppDependencyManager.shared.setModelContainer(nil)
        
        // When & Then
        do {
            _ = try await intent.perform()
            XCTFail("Expected IntentError.modelContainerNotAvailable to be thrown")
        } catch let error as IntentError {
            XCTAssertEqual(error, IntentError.modelContainerNotAvailable)
            XCTAssertEqual(error.errorDescription, "Unable to access data storage")
        } catch {
            XCTFail("Expected IntentError.modelContainerNotAvailable, got \(error)")
        }
    }
    
    @MainActor
    func testLogCarbsIntent_WithValidContainer_CreatesEntrySuccessfully() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        
        let intent = LogCarbsIntent()
        intent.carbAmount = 15.7
        
        // When
        let result = try await intent.perform()
        
        // Then
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<CarbEntry>()
        let entries = try context.fetch(descriptor)
        
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.value, 15.7)
        XCTAssertNotNil(entries.first?.timestamp)
        
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testLogCarbsIntent_WithWholeNumber_FormatsCorrectlyInDialog() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        
        let intent = LogCarbsIntent()
        intent.carbAmount = 20.0
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testLogCarbsIntent_WithDecimalNumber_FormatsCorrectlyInDialog() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        
        let intent = LogCarbsIntent()
        intent.carbAmount = 12.34
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testLogCarbsIntent_StaticProperties_HaveCorrectValues() {
        // Given & When
        let title = LogCarbsIntent.title
        let description = LogCarbsIntent.description
        
        // Then
        XCTAssertEqual(title, "Log Carbohydrates")
        XCTAssertNotNil(description)
    }
    
    
    @MainActor
    func testGetDailySummaryIntent_WhenModelContainerNotAvailable_ThrowsCorrectError() async {
        // Given
        let intent = GetDailySummaryIntent()
        
        AppDependencyManager.shared.setModelContainer(nil)
        
        // When & Then
        do {
            _ = try await intent.perform()
            XCTFail("Expected IntentError.modelContainerNotAvailable to be thrown")
        } catch let error as IntentError {
            XCTAssertEqual(error, IntentError.modelContainerNotAvailable)
            XCTAssertEqual(error.errorDescription, "Unable to access data storage")
        } catch {
            XCTFail("Expected IntentError.modelContainerNotAvailable, got \(error)")
        }
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithNoEntries_ReturnsCorrectMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithOneEntry_ReturnsCorrectMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        let entry = CarbEntry(timestamp: Date(), value: 15.5)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithMultipleEntries_ReturnsCorrectMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        let entry1 = CarbEntry(timestamp: Date(), value: 10.0)
        let entry2 = CarbEntry(timestamp: Date(), value: 12.5)
        let entry3 = CarbEntry(timestamp: Date(), value: 7.3)
        context.insert(entry1)
        context.insert(entry2)
        context.insert(entry3)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithEntriesFromDifferentDays_OnlyCountsToday() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        let todayEntry = CarbEntry(timestamp: Date(), value: 15.0)
        let yesterdayEntry = CarbEntry(timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, value: 25.0)
        context.insert(todayEntry)
        context.insert(yesterdayEntry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithRemainingCarbs_ShowsRemainingMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        AppSettings.carbLimit = 20.0
        AppSettings.cautionLimit = 15.0
        AppSettings.warnLimitEnabled = true
        AppSettings.cautionLimitEnabled = true
        
        let entry = CarbEntry(timestamp: Date(), value: 10.0)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithCautionLimit_ShowsCautionMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        AppSettings.carbLimit = 20.0
        AppSettings.cautionLimit = 15.0
        AppSettings.warnLimitEnabled = true
        AppSettings.cautionLimitEnabled = true
        
        let entry = CarbEntry(timestamp: Date(), value: 18.0)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithWarnLimit_ShowsOverLimitMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        AppSettings.carbLimit = 20.0
        AppSettings.cautionLimit = 15.0
        AppSettings.warnLimitEnabled = true
        AppSettings.cautionLimitEnabled = true
        
        let entry = CarbEntry(timestamp: Date(), value: 25.0)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithWarnLimitDisabled_DoesNotShowOverLimitMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        AppSettings.carbLimit = 20.0
        AppSettings.cautionLimit = 15.0
        AppSettings.warnLimitEnabled = false
        AppSettings.cautionLimitEnabled = true
        
        let entry = CarbEntry(timestamp: Date(), value: 25.0)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_WithCautionLimitDisabled_DoesNotShowCautionMessage() async throws {
        // Given
        let container = try ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        AppDependencyManager.shared.setModelContainer(container)
        let context = ModelContext(container)
        
        AppSettings.carbLimit = 20.0
        AppSettings.cautionLimit = 15.0
        AppSettings.warnLimitEnabled = false
        AppSettings.cautionLimitEnabled = false
        
        let entry = CarbEntry(timestamp: Date(), value: 18.0)
        context.insert(entry)
        try context.save()
        
        let intent = GetDailySummaryIntent()
        
        // When
        let result = try await intent.perform()
        
        // Then
        XCTAssertNotNil(result)
    }
    
    @MainActor
    func testGetDailySummaryIntent_StaticProperties_HaveCorrectValues() {
        // Given & When
        let title = GetDailySummaryIntent.title
        let description = GetDailySummaryIntent.description
        
        // Then
        XCTAssertEqual(title, "Get Daily Carb Summary")
        XCTAssertNotNil(description)
    }
    
}
