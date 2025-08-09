//
//  CarbClarity_Watch_AppTests.swift
//  CarbClarity Watch AppTests
//
//  Created by René Fouquet on 18.07.25.
//

import XCTest
import SwiftData
import ClockKit
@testable import CarbClarity_Watch_App

@MainActor
final class CarbClarity_Watch_AppTests: XCTestCase, @unchecked Sendable {
    
    var viewModel: WatchViewModel!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        MainActor.assumeIsolated {
            modelContext = ModelContext(container)
            viewModel = WatchViewModel(modelContext: modelContext)
        }
    }
    
    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            viewModel = nil
            modelContext = nil
        }
    }
    
    // MARK: - WatchViewModel Tests
    
    func testWatchViewModelInitialization() {
        // Given
        
        // When & Then
        XCTAssertNil(viewModel.inputValue)
        XCTAssertFalse(viewModel.showingAddView)
        XCTAssertEqual(viewModel.carbLimit, 20.0)
        XCTAssertEqual(viewModel.cautionLimit, 15.0)
        XCTAssertTrue(viewModel.warnLimitEnabled)
        XCTAssertTrue(viewModel.cautionLimitEnabled)
    }
    
    func testTotalCarbsForTodayEmpty() {
        // Given
        
        // When & Then
        XCTAssertEqual(viewModel.totalCarbsForToday, 0.0)
        XCTAssertEqual(viewModel.totalCarbsForTodayString, "0g")
    }
    
    func testTotalCarbsForTodayWithEntries() {
        // Given
        let entry1 = CarbEntry(timestamp: Date(), value: 5.5)
        let entry2 = CarbEntry(timestamp: Date(), value: 10.2)
        modelContext.insert(entry1)
        modelContext.insert(entry2)
        
        let entries = [entry1, entry2]
        
        // When
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: entries,
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        // Then
        XCTAssertEqual(viewModel.totalCarbsForToday, 15.7)
    }
    
    func testIsExceedingCarbLimit() {
        let entry = CarbEntry(timestamp: Date(), value: 25.0)
        modelContext.insert(entry)
        
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: [entry],
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        XCTAssertTrue(viewModel.isExceedingCarbLimit)
    }
    
    func testIsExceedingCautionLimit() {
        let entry = CarbEntry(timestamp: Date(), value: 17.0)
        modelContext.insert(entry)
        
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: [entry],
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        XCTAssertTrue(viewModel.isExceedingCautionLimit)
        XCTAssertFalse(viewModel.isExceedingCarbLimit)
    }
    
    func testCarbDisplayColors() {
        let normalEntry = CarbEntry(timestamp: Date(), value: 10.0)
        modelContext.insert(normalEntry)
        
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: [normalEntry],
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        XCTAssertEqual(viewModel.todaysCarbDisplayColor, .normal)
        
        modelContext.delete(normalEntry)
        let cautionEntry = CarbEntry(timestamp: Date(), value: 17.0)
        modelContext.insert(cautionEntry)
        
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: [cautionEntry],
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        XCTAssertEqual(viewModel.todaysCarbDisplayColor, .caution)
        
        modelContext.delete(cautionEntry)
        let warningEntry = CarbEntry(timestamp: Date(), value: 25.0)
        modelContext.insert(warningEntry)
        
        viewModel.updateDependencies(
            modelContext: modelContext,
            allEntries: [warningEntry],
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true
        )
        
        XCTAssertEqual(viewModel.todaysCarbDisplayColor, .warning)
    }
    
    func testCanAddEntryValidation() {
        viewModel.inputValue = nil
        XCTAssertFalse(viewModel.canAddEntry)
        
        viewModel.inputValue = 0.0
        XCTAssertFalse(viewModel.canAddEntry)
        
        viewModel.inputValue = -5.0
        XCTAssertFalse(viewModel.canAddEntry)
        
        viewModel.inputValue = 5.5
        XCTAssertTrue(viewModel.canAddEntry)
    }
    
    func testAddItem() {
        // Given
        viewModel.inputValue = 12.5
        
        // When
        let success = viewModel.addItem()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertNil(viewModel.inputValue)
        
        do {
            let entries = try modelContext.fetch(FetchDescriptor<CarbEntry>())
            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries.first?.value, 12.5)
        } catch {
            XCTFail("Failed to fetch entries: \(error)")
        }
    }
    
    func testQuickAdd() {
        // Given
        
        // When
        let success = viewModel.quickAdd(7.5)
        
        // Then
        XCTAssertTrue(success)
        
        do {
            let entries = try modelContext.fetch(FetchDescriptor<CarbEntry>())
            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries.first?.value, 7.5)
        } catch {
            XCTFail("Failed to fetch entries: \(error)")
        }
    }
    
    func testShowHideAddView() {
        // Given
        XCTAssertFalse(viewModel.showingAddView)
        
        // When
        viewModel.showAddView()
        
        // Then
        XCTAssertTrue(viewModel.showingAddView)
        
        // When
        viewModel.hideAddView()
        
        // Then
        XCTAssertFalse(viewModel.showingAddView)
    }
}
