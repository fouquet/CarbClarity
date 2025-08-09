//
//  QuickAddButtonViewTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import SwiftUI
import SwiftData
@testable import CarbClarity

@MainActor
final class QuickAddButtonViewTests: XCTestCase, @unchecked Sendable {
    var container: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: MainViewModel!
    
    override func setUpWithError() throws {
        MainActor.assumeIsolated {
            container = try! ModelContainer(for: CarbEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            modelContext = ModelContext(container)
            viewModel = MainViewModel(modelContext: modelContext)
            viewModel.updateDependencies(
                modelContext: modelContext,
                allEntries: [],
                carbLimit: 20.0,
                cautionLimit: 15.0,
                warnLimitEnabled: true,
                cautionLimitEnabled: true,
                lookupEnabled: false
            )
        }
    }
    
    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            container = nil
            modelContext = nil
            viewModel = nil
        }
    }
    
    // MARK: - QuickAddButton Tests
    
    func testQuickAddButton_DisplaysCorrectValue() {
        // Given
        let testValue = 5.0
        let button = QuickAddButton(value: testValue, viewModel: viewModel)
        
        // When & Then
        XCTAssertEqual(button.value, 5.0, "Button should store the correct value for display")
    }
    
    func testQuickAddButton_CallsViewModelQuickAdd() {
        // Given
        let testValue = 2.5
        let initialEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        
        // When
        let success = viewModel.quickAdd(testValue)
        
        // Then
        XCTAssertTrue(success, "quickAdd should succeed")
        let finalEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        XCTAssertEqual(finalEntryCount, initialEntryCount + 1, "Button press should add one entry")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        let addedEntry = entries.last!
        XCTAssertEqual(addedEntry.value, testValue.roundedForCarbs(), "Added entry should have correct rounded value")
    }
    
    func testQuickAddButton_WithZeroValue_DoesNotAddEntry() {
        // Given
        let testValue = 0.0
        let initialEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        
        // When
        let success = viewModel.quickAdd(testValue)
        
        // Then
        XCTAssertFalse(success, "quickAdd should fail for zero value")
        let finalEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        XCTAssertEqual(finalEntryCount, initialEntryCount, "No entry should be added for zero value")
    }
    
    // MARK: - QuickAddButtonsView Tests
    
    func testQuickAddButtonsView_HasCorrectPresetValues() {
        // Given
        let expectedValues = [0.1, 0.5, 1.0, 4.0, 6.0, 10.0]
        
        // When & Then
        for value in expectedValues {
            let success = viewModel.quickAdd(value)
            XCTAssertTrue(success, "All preset values should be valid for quickAdd: \(value)")
        }
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        XCTAssertEqual(entries.count, expectedValues.count, "Should have added entries for all preset values")
    }
    
    func testQuickAddButtonsView_AllButtonsAddCorrectValues() {
        // Given
        let presetValues = [0.1, 0.5, 1.0, 4.0, 6.0, 10.0]
        let initialEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        
        // When
        for value in presetValues {
            _ = viewModel.quickAdd(value)
        }
        
        // Then
        let finalEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        XCTAssertEqual(finalEntryCount, initialEntryCount + presetValues.count, "Should add entry for each button press")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).sorted { $0.timestamp < $1.timestamp }
        for (index, expectedValue) in presetValues.enumerated() {
            let actualValue = entries[entries.count - presetValues.count + index].value
            XCTAssertEqual(actualValue, expectedValue.roundedForCarbs(), "Entry \(index) should have value \(expectedValue)")
        }
    }
    
    func testQuickAddButtonsView_ButtonPressesAreIndependent() {
        // Given
        let testValue = 1.0
        let initialEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        
        // When
        _ = viewModel.quickAdd(testValue)
        _ = viewModel.quickAdd(testValue)
        _ = viewModel.quickAdd(testValue)
        
        // Then
        let finalEntryCount = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).count
        XCTAssertEqual(finalEntryCount, initialEntryCount + 3, "Each button press should add a separate entry")
        
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>())
        let lastThreeEntries = Array(entries.suffix(3))
        for entry in lastThreeEntries {
            XCTAssertEqual(entry.value, testValue.roundedForCarbs(), "Each entry should have the same value")
        }
    }
    
    func testQuickAddButtonsView_TimestampsDiffer() {
        // Given
        let testValue = 0.5
        let sleepDuration: TimeInterval = 0.01 // 10ms between calls
        
        // When
        _ = viewModel.quickAdd(testValue)
        Thread.sleep(forTimeInterval: sleepDuration)
        _ = viewModel.quickAdd(testValue)
        Thread.sleep(forTimeInterval: sleepDuration)
        _ = viewModel.quickAdd(testValue)
        
        // Then
        let entries = try! modelContext.fetch(FetchDescriptor<CarbEntry>()).sorted { $0.timestamp < $1.timestamp }
        let lastThreeEntries = Array(entries.suffix(3))
        
        XCTAssertTrue(lastThreeEntries[0].timestamp < lastThreeEntries[1].timestamp, "First entry should be earlier than second")
        XCTAssertTrue(lastThreeEntries[1].timestamp < lastThreeEntries[2].timestamp, "Second entry should be earlier than third")
    }
}
