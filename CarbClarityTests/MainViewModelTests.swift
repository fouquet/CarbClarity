//
//  MainViewModelTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 13.07.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

@MainActor
final class MainViewModelTests: XCTestCase, @unchecked Sendable {
    
    var sut: MainViewModel!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        MainActor.assumeIsolated {
            modelContext = ModelContext(container)
            sut = MainViewModel(modelContext: modelContext)
        }
    }

    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            sut = nil
            modelContext = nil
        }
    }
    
    // MARK: - Initialization Tests
    
    
    // MARK: - CarbEntriesByDay Tests
    
    func testCarbEntriesByDay_WithNoEntries_ReturnsEmptyArray() {
        // Given
        
        // When
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // Then
        XCTAssertTrue(sut.carbEntriesByDay.isEmpty)
    }
    
    func testCarbEntriesByDay_WithMultipleDays_GroupsAndSortsCorrectly() {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let entries = [
            CarbEntry(timestamp: today, value: 10.0),
            CarbEntry(timestamp: today, value: 5.0),
            CarbEntry(timestamp: yesterday, value: 15.0)
        ]
        
        // When
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // Then
        let groupedEntries = sut.carbEntriesByDay
        XCTAssertEqual(groupedEntries.count, 2)
        XCTAssertTrue(Calendar.current.isDate(groupedEntries[0].day, inSameDayAs: today))
        XCTAssertTrue(Calendar.current.isDate(groupedEntries[1].day, inSameDayAs: yesterday))
        XCTAssertEqual(groupedEntries[0].entries.count, 2)
        XCTAssertEqual(groupedEntries[1].entries.count, 1)
    }
    
    func testCarbEntriesByDay_WithComplexTimestamps_SortsEntriesCorrectly() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let todayMorning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today)!
        let todayAfternoon = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: today)!
        let todayEvening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!
        
        let yesterdayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: yesterday)!
        let yesterdayEvening = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: yesterday)!
        
        let entries = [
            CarbEntry(timestamp: todayMorning, value: 5.0),
            CarbEntry(timestamp: yesterdayEvening, value: 8.0),
            CarbEntry(timestamp: todayEvening, value: 10.0),
            CarbEntry(timestamp: yesterdayMorning, value: 6.0),
            CarbEntry(timestamp: todayAfternoon, value: 7.0)
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let sortedDays = sut.carbEntriesByDay
        XCTAssertEqual(sortedDays.count, 2)
        XCTAssertTrue(calendar.isDate(sortedDays[0].day, inSameDayAs: today))
        XCTAssertTrue(calendar.isDate(sortedDays[1].day, inSameDayAs: yesterday))
        
        let todayEntries = sortedDays[0].entries
        XCTAssertEqual(todayEntries.count, 3)
        XCTAssertEqual(todayEntries[0].value, 10.0) // Evening
        XCTAssertEqual(todayEntries[1].value, 7.0)  // Afternoon
        XCTAssertEqual(todayEntries[2].value, 5.0)  // Morning
        
        let yesterdayEntries = sortedDays[1].entries
        XCTAssertEqual(yesterdayEntries.count, 2)
        XCTAssertEqual(yesterdayEntries[0].value, 8.0) // Evening
        XCTAssertEqual(yesterdayEntries[1].value, 6.0) // Morning
    }
    
    func testCarbEntriesByDay_WithSameTimestamp_HandlesGracefully() {
        let calendar = Calendar.current
        let today = Date()
        let sameTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        let entries = [
            CarbEntry(timestamp: sameTime, value: 5.0),
            CarbEntry(timestamp: sameTime, value: 10.0),
            CarbEntry(timestamp: sameTime, value: 7.0)
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let sortedDays = sut.carbEntriesByDay
        XCTAssertEqual(sortedDays.count, 1)
        let dayEntries = sortedDays[0].entries
        XCTAssertEqual(dayEntries.count, 3)
        
        let values = dayEntries.map { $0.value }
        XCTAssertTrue(values.contains(5.0))
        XCTAssertTrue(values.contains(10.0))
        XCTAssertTrue(values.contains(7.0))
    }
    
    func testCarbEntriesByDay_WithEmptyEntries_ReturnsEmpty() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let sortedDays = sut.carbEntriesByDay
        XCTAssertEqual(sortedDays.count, 0)
    }
    
    // MARK: - Today's Total Carbs Tests
    
    func testTotalCarbsForToday_WithNoEntries_ReturnsZero() {
        // Given
        
        // When
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // Then
        XCTAssertEqual(sut.totalCarbsForToday, 0.0)
    }
    
    func testTotalCarbsForToday_WithTodaysEntries_ReturnsCorrectTotal() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let entries = [
            CarbEntry(timestamp: today, value: 10.0),
            CarbEntry(timestamp: today, value: 5.5),
            CarbEntry(timestamp: yesterday, value: 15.0)
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertEqual(sut.totalCarbsForToday, 15.5)
    }
    
    func testTotalCarbsForToday_WithRoundedValues_CalculatesCorrectly() {
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 12.555.roundedForCarbs()), // 12.56
            CarbEntry(timestamp: today, value: 5.444.roundedForCarbs()),  // 5.44
            CarbEntry(timestamp: today, value: 2.001.roundedForCarbs())   // 2.0
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let total = sut.totalCarbsForToday
        XCTAssertEqual(total, 20.0)
    }
    
    func testTotalCarbsForTodayString_WithEntries_ReturnsFormattedString() {
        let today = Date()
        let entries = [CarbEntry(timestamp: today, value: 12.5)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertEqual(sut.totalCarbsForTodayString, "12.5g")
    }
    
    func testTotalCarbsForTodayString_WithRoundedValues_ReturnsFormattedString() {
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 12.555.roundedForCarbs()), // 12.56
            CarbEntry(timestamp: today, value: 5.44.roundedForCarbs())    // 5.44
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let totalString = sut.totalCarbsForTodayString
        XCTAssertEqual(totalString, "18g")
    }
    
    // MARK: - Limit Checking Tests
    
    func testIsExceedingCarbLimit_WithVariousValues_ReturnsCorrectResults() {
        let today = Date()
        
        // When & Then
        let entriesUnder = [CarbEntry(timestamp: today, value: 15.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesUnder, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertFalse(sut.isExceedingCarbLimit)
        
        // When & Then
        let entriesAt = [CarbEntry(timestamp: today, value: 20.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesAt, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertFalse(sut.isExceedingCarbLimit)
        
        // When & Then
        let entriesOver = [CarbEntry(timestamp: today, value: 25.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertTrue(sut.isExceedingCarbLimit)
    }
    
    func testIsExceedingCarbLimit_WithToggleDisabled_ReturnsFalse() {
        let today = Date()
        let entriesOver = [CarbEntry(timestamp: today, value: 25.0)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: false, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertFalse(sut.isExceedingCarbLimit)
    }
    
    func testIsExceedingCautionLimit_WithVariousValues_ReturnsCorrectResults() {
        let today = Date()
        
        // When & Then
        let entriesUnder = [CarbEntry(timestamp: today, value: 10.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesUnder, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertFalse(sut.isExceedingCautionLimit)
        
        // When & Then
        let entriesAt = [CarbEntry(timestamp: today, value: 15.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesAt, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertFalse(sut.isExceedingCautionLimit)
        
        // When & Then
        let entriesOver = [CarbEntry(timestamp: today, value: 17.0)]
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertTrue(sut.isExceedingCautionLimit)
    }
    
    func testIsExceedingCautionLimit_WithCautionLimitDisabled_ReturnsFalse() {
        let today = Date()
        let entriesOver = [CarbEntry(timestamp: today, value: 17.0)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: false, lookupEnabled: false)
        
        XCTAssertFalse(sut.isExceedingCautionLimit)
    }
    
    func testCarbLimitWarning_WithRoundedValues_TriggersCorrectly() {
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 10.555.roundedForCarbs()), // 10.56
            CarbEntry(timestamp: today, value: 9.445.roundedForCarbs())   // 9.44
        ]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 19.99, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertTrue(sut.isExceedingCarbLimit)
        XCTAssertEqual(sut.todaysCarbDisplayColor, .warning)
    }
    
    // MARK: - Display Color Tests
    
    func testTodaysCarbDisplayColor_WithNormalValues_ReturnsNormal() {
        let today = Date()
        let entriesUnder = [CarbEntry(timestamp: today, value: 10.0)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesUnder, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertEqual(sut.todaysCarbDisplayColor, .normal)
    }
    
    func testTodaysCarbDisplayColor_WithCautionLevel_ReturnsCaution() {
        let today = Date()
        let entriesCaution = [CarbEntry(timestamp: today, value: 17.0)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesCaution, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertEqual(sut.todaysCarbDisplayColor, .caution)
    }
    
    func testTodaysCarbDisplayColor_WithWarningLevel_ReturnsWarning() {
        let today = Date()
        let entriesOver = [CarbEntry(timestamp: today, value: 25.0)]
        
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        XCTAssertEqual(sut.todaysCarbDisplayColor, .warning)
    }
    
    func testTodaysCarbDisplayColor_WithDisabledLimits_ReturnsAppropriateColors() {
        let today = Date()
        let entriesOver = [CarbEntry(timestamp: today, value: 25.0)]
        
        // When & Then
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: false, cautionLimitEnabled: false, lookupEnabled: false)
        XCTAssertEqual(sut.todaysCarbDisplayColor, .normal)
        
        // When & Then
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: false, cautionLimitEnabled: true, lookupEnabled: false)
        XCTAssertEqual(sut.todaysCarbDisplayColor, .caution)
        
        // When & Then
        sut.updateDependencies(modelContext: modelContext, allEntries: entriesOver, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: false, lookupEnabled: false)
        XCTAssertEqual(sut.todaysCarbDisplayColor, .warning)
    }
    
    // MARK: - Input Validation Tests
    
    
    // MARK: - User Action Tests
    
    
    
    // MARK: - Add Item Tests
    
    func testAddItem_WithValidInput_AddsEntryAndClearsInput() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        sut.inputValue = 12.5
        
        // When
        let result = sut.addItem()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertNil(sut.inputValue)
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].value, 12.5)
    }
    
    func testAddItem_WithoutModelContext_ReturnsFalse() {
        // Given
        let sutWithoutContext = MainViewModel(modelContext: nil)
        sutWithoutContext.inputValue = 10.0
        
        // When
        let result = sutWithoutContext.addItem()
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testAddItem_WithInvalidInput_ReturnsFalseAndDoesNotAddEntry() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When & Then
        sut.inputValue = nil
        XCTAssertFalse(sut.addItem())
        
        // When & Then
        sut.inputValue = 0.0
        XCTAssertFalse(sut.addItem())
        
        // When & Then
        sut.inputValue = -5.0
        XCTAssertFalse(sut.addItem())
        
        // Then
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0)
    }
    
    func testAddItem_WithRoundingValues_RoundsCorrectly() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let testCases = [
            (input: 12.555, expected: 12.56),
            (input: 12.554, expected: 12.55),
            (input: 5.0, expected: 5.0),
            (input: 0.999, expected: 1.0)
        ]
        
        for (input, expected) in testCases {
            let existingEntries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
            for entry in existingEntries {
                modelContext.delete(entry)
            }
            
            sut.inputValue = input
            let result = sut.addItem()
            
            XCTAssertTrue(result, "Should successfully add item with input: \(input)")
            
            let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
            XCTAssertEqual(entries.count, 1)
            let entry = entries.first!
            
            XCTAssertEqual(entry.value, expected, "Input: \(input) should be rounded to \(expected)")
        }
    }
    
    func testAddItem_WithPreciseDecimals_PreservesValue() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        sut.inputValue = 12.34
        
        _ = sut.addItem()
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        let entry = entries.last!
        XCTAssertEqual(entry.value, 12.34)
    }
    
    func testAddItem_WithVerySmallValues_RoundsToMinimum() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        sut.inputValue = 0.005
        
        _ = sut.addItem()
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        let entry = entries.last!
        XCTAssertEqual(entry.value, 0.01)
    }
    
    func testAddItem_WithValuesRoundingToZero_RejectsEntry() {
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let testCases = [0.004, 0.001, 0.0001]
        
        for input in testCases {
            sut.inputValue = input
            let result = sut.addItem()
            
            XCTAssertFalse(result, "Should reject input \(input) that rounds to 0")
            
            let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
            XCTAssertEqual(entries.count, 0, "No entries should be added for input \(input)")
        }
    }
    
    // MARK: - Delete Item Tests
    
    func testDeleteItems_WithValidEntries_DeletesCorrectEntries() {
        // Given
        let entry1 = CarbEntry(timestamp: Date(), value: 10.0)
        let entry2 = CarbEntry(timestamp: Date(), value: 15.0)
        let entry3 = CarbEntry(timestamp: Date(), value: 5.0)
        
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        modelContext.insert(entry3)
        
        let entries = [entry1, entry2, entry3]
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        let result = sut.deleteItems(items: entries, offsets: IndexSet([1]))
        
        // Then
        XCTAssertTrue(result)
        
        let remainingEntries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(remainingEntries.count, 2)
        XCTAssertFalse(remainingEntries.contains(entry2))
        XCTAssertTrue(remainingEntries.contains(entry1))
        XCTAssertTrue(remainingEntries.contains(entry3))
    }
    
    func testDeleteItems_WithoutModelContext_ReturnsFalse() {
        // Given
        let sutWithoutContext = MainViewModel(modelContext: nil)
        let entries = [CarbEntry(timestamp: Date(), value: 10.0)]
        
        // When
        let result = sutWithoutContext.deleteItems(items: entries, offsets: IndexSet([0]))
        
        // Then
        XCTAssertFalse(result)
    }
    
    func testDeleteItems_WithMultipleEntries_DeletesAllSpecifiedEntries() {
        let entry1 = CarbEntry(timestamp: Date(), value: 10.0)
        let entry2 = CarbEntry(timestamp: Date(), value: 15.0)
        let entry3 = CarbEntry(timestamp: Date(), value: 5.0)
        
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        modelContext.insert(entry3)
        
        let entries = [entry1, entry2, entry3]
        sut.updateDependencies(modelContext: modelContext, allEntries: entries, carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let result = sut.deleteItems(items: entries, offsets: IndexSet([0, 2]))
        
        XCTAssertTrue(result)
        
        let remainingEntries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(remainingEntries.count, 1)
        XCTAssertTrue(remainingEntries.contains(entry2))
        XCTAssertFalse(remainingEntries.contains(entry1))
        XCTAssertFalse(remainingEntries.contains(entry3))
    }
    
    // MARK: - Day Total Tests
    
    func testDayTotal_WithEntriesUnderLimit_ReturnsFormattedTotal() {
        // Given
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 5.0),
            CarbEntry(timestamp: today, value: 10.0)
        ]
        let dayEntry = CarbEntryByDay(day: today, entries: entries)
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        let totalString = sut.dayTotal(for: dayEntry)
        
        // Then
        XCTAssertEqual(totalString, "Total: 15g")
    }
    
    func testDayTotal_WithEntriesOverLimit_ReturnsFormattedTotalWithWarning() {
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 15.0),
            CarbEntry(timestamp: today, value: 10.0)
        ]
        let dayEntry = CarbEntryByDay(day: today, entries: entries)
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let totalString = sut.dayTotal(for: dayEntry)
        
        XCTAssertEqual(totalString, "Total: 25g ⚠️")
    }
    
    func testDayTotal_WithRoundedValues_CalculatesCorrectly() {
        let today = Date()
        let entries = [
            CarbEntry(timestamp: today, value: 12.555.roundedForCarbs()), // 12.56
            CarbEntry(timestamp: today, value: 7.444.roundedForCarbs())   // 7.44
        ]
        let dayEntry = CarbEntryByDay(day: today, entries: entries)
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 30.0, cautionLimit: 25.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        let totalString = sut.dayTotal(for: dayEntry)
        
        XCTAssertEqual(totalString, "Total: 20g")
    }
    
    // MARK: - Update Dependencies Tests
    
    func testUpdateDependencies_WithValidParameters_UpdatesAllProperties() {
        // Given
        let entries = [CarbEntry(timestamp: Date(), value: 10.0)]
        
        // When
        sut.updateDependencies(
            modelContext: modelContext,
            allEntries: entries,
            carbLimit: 30.0,
            cautionLimit: 25.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: true
        )
        
        // Then
        XCTAssertEqual(sut.carbLimit, 30.0)
        XCTAssertTrue(sut.lookupEnabled)
        XCTAssertEqual(sut.carbEntriesByDay.count, 1)
    }
    
    // MARK: - Dummy Data Tests
    
    func testAddDummyData_WithModelContext_AddsExpectedNumberOfEntries() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        sut.addDummyData()
        
        // Then
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 8)
        
        let firstEntry = entries.first { $0.value == 1.0 }
        XCTAssertNotNil(firstEntry)
        
        let largestEntry = entries.first { $0.value == 12.0 }
        XCTAssertNotNil(largestEntry)
    }
    
    func testAddDummyData_WithoutModelContext_DoesNotCrash() {
        // Given
        let sutWithoutContext = MainViewModel(modelContext: nil)
        
        // When
        sutWithoutContext.addDummyData()
        
        // Then
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0)
    }
    
    // MARK: - QuickAdd Tests
    
    func testQuickAdd_WithValidValue_AddsEntryAndReturnsTrue() throws {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        let testValue = 5.0
        
        // When
        let result = sut.quickAdd(testValue)
        
        // Then
        XCTAssertTrue(result, "quickAdd should return true for valid input")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 1, "Should add one entry")
        let entry = try XCTUnwrap(entries.first, "Should have one entry")
        XCTAssertEqual(entry.value, testValue, "Entry should have the correct value")
    }
    
    func testQuickAdd_WithZeroValue_ReturnsFalseAndDoesNotAddEntry() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        let result = sut.quickAdd(0.0)
        
        // Then
        XCTAssertFalse(result, "quickAdd should return false for zero input")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0, "Should not add any entries for zero value")
    }
    
    func testQuickAdd_WithNegativeValue_ReturnsFalseAndDoesNotAddEntry() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        let result = sut.quickAdd(-1.0)
        
        // Then
        XCTAssertFalse(result, "quickAdd should return false for negative input")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0, "Should not add any entries for negative value")
    }
    
    func testQuickAdd_WithoutModelContext_ReturnsFalse() {
        // Given
        let sutWithoutContext = MainViewModel(modelContext: nil)
        
        // When
        let result = sutWithoutContext.quickAdd(5.0)
        
        // Then
        XCTAssertFalse(result, "quickAdd should return false without model context")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0, "Should not add any entries without model context")
    }
    
    func testQuickAdd_WithRoundingValues_RoundsCorrectly() throws {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        let testValue = 5.567  // Should round to 5.57
        
        // When
        let result = sut.quickAdd(testValue)
        
        // Then
        XCTAssertTrue(result, "quickAdd should return true for valid input")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 1, "Should add one entry")
        let entry = try XCTUnwrap(entries.first, "Should have one entry")
        XCTAssertEqual(entry.value, 5.57, accuracy: 0.001, "Entry should have the rounded value")
    }
    
    func testQuickAdd_WithVerySmallValues_RoundsToMinimum() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        let testValue = 0.001  // Should round to 0.00 and be rejected
        
        // When
        let result = sut.quickAdd(testValue)
        
        // Then
        XCTAssertFalse(result, "quickAdd should return false for values that round to zero")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 0, "Should not add entries that round to zero")
    }
    
    func testQuickAdd_WithPresetWatchValues_AddsCorrectly() {
        // Given - Test all the preset values from the Watch app
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        let presetValues = [0.1, 0.5, 1.0, 4.0, 6.0, 10.0]
        
        // When & Then
        for value in presetValues {
            let result = sut.quickAdd(value)
            XCTAssertTrue(result, "quickAdd should return true for preset value \(value)")
        }
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, presetValues.count, "Should add entries for all preset values")
        
        // Verify all values are present
        let entryValues = Set(entries.map { $0.value })
        let expectedValues = Set(presetValues)
        XCTAssertEqual(entryValues, expectedValues, "All preset values should be added correctly")
    }
    
    func testQuickAdd_MultipleCalls_AddsMultipleEntries() {
        // Given
        sut.updateDependencies(modelContext: modelContext, allEntries: [], carbLimit: 20.0, cautionLimit: 15.0, warnLimitEnabled: true, cautionLimitEnabled: true, lookupEnabled: false)
        
        // When
        let result1 = sut.quickAdd(1.0)
        let result2 = sut.quickAdd(2.0)
        let result3 = sut.quickAdd(3.0)
        
        // Then
        XCTAssertTrue(result1, "First quickAdd should succeed")
        XCTAssertTrue(result2, "Second quickAdd should succeed")
        XCTAssertTrue(result3, "Third quickAdd should succeed")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, 3, "Should add three separate entries")
        
        let values = entries.map { $0.value }.sorted()
        XCTAssertEqual(values, [1.0, 2.0, 3.0], "Should add all values correctly")
    }
}
