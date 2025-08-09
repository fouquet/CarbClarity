//
//  CarbEntryByDayTestsSimplified.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

final class CarbEntryByDayTests: XCTestCase {
    
    func testInit_WithDayAndEntries_SetsPropertiesCorrectly() {
        // Given
        let testDay = Date()
        let entries = [
            CarbEntry(timestamp: testDay, value: 15.0),
            CarbEntry(timestamp: testDay, value: 20.0),
            CarbEntry(timestamp: testDay, value: 10.0)
        ]
        
        // When
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // Then
        XCTAssertEqual(sut.day, testDay)
        XCTAssertEqual(sut.entries.count, 3)
        XCTAssertEqual(sut.entries[0].value, 15.0)
        XCTAssertEqual(sut.entries[1].value, 20.0)
        XCTAssertEqual(sut.entries[2].value, 10.0)
    }
    
    func testTotal_WithEmptyEntries_ReturnsZero() {
        // Given
        let testDay = Date()
        let sut = CarbEntryByDay(day: testDay, entries: [])
        
        // When
        let total = sut.total()
        
        // Then
        XCTAssertEqual(total, 0.0)
    }
    
    func testTotal_WithMultipleEntries_ReturnsCorrectSum() {
        // Given
        let testDay = Date()
        let entries = [
            CarbEntry(timestamp: testDay, value: 10.0),
            CarbEntry(timestamp: testDay, value: 15.5),
            CarbEntry(timestamp: testDay, value: 8.25),
            CarbEntry(timestamp: testDay, value: 12.0)
        ]
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // When
        let total = sut.total()
        
        // Then
        XCTAssertEqual(total, 45.75, accuracy: 0.001)
    }
    
    func testTotal_WithZeroValues_HandlesCorrectly() {
        // Given
        let testDay = Date()
        let entries = [
            CarbEntry(timestamp: testDay, value: 0.0),
            CarbEntry(timestamp: testDay, value: 10.0),
            CarbEntry(timestamp: testDay, value: 0.0),
            CarbEntry(timestamp: testDay, value: 5.0)
        ]
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // When
        let total = sut.total()
        
        // Then
        XCTAssertEqual(total, 15.0)
    }
    
    func testTotal_CalledMultipleTimes_ReturnsSameResult() {
        // Given
        let testDay = Date()
        let entries = [
            CarbEntry(timestamp: testDay, value: 10.0),
            CarbEntry(timestamp: testDay, value: 20.0),
            CarbEntry(timestamp: testDay, value: 30.0)
        ]
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // When
        let total1 = sut.total()
        let total2 = sut.total()
        let total3 = sut.total()
        
        // Then
        XCTAssertEqual(total1, 60.0)
        XCTAssertEqual(total2, 60.0)
        XCTAssertEqual(total3, 60.0)
    }
    
    func testInit_WithDifferentDates_StoresCorrectDate() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let entries = [CarbEntry(timestamp: today, value: 10.0)]
        
        // When
        let yesterdayEntry = CarbEntryByDay(day: yesterday, entries: entries)
        let tomorrowEntry = CarbEntryByDay(day: tomorrow, entries: entries)
        
        // Then
        XCTAssertEqual(yesterdayEntry.day, yesterday)
        XCTAssertEqual(tomorrowEntry.day, tomorrow)
        XCTAssertNotEqual(yesterdayEntry.day, tomorrowEntry.day)
    }
    
    // MARK: - Coverage Tests
    
    func testCarbEntryByDay_WithDifferentEntryConfigurations() {
        // Given
        let testDay = Date()
        let configurations = [
            [], // Empty entries
            [CarbEntry(timestamp: testDay, value: 5.0)], // Single entry
            [CarbEntry(timestamp: testDay, value: 10.0), CarbEntry(timestamp: testDay, value: 15.0)], // Multiple entries
            [CarbEntry(timestamp: testDay, value: 0.0), CarbEntry(timestamp: testDay, value: 25.5)] // With zero value
        ]
        
        // When & Then
        for (index, entries) in configurations.enumerated() {
            let sut = CarbEntryByDay(day: testDay, entries: entries)
            
            XCTAssertEqual(sut.day, testDay, "Day should be set correctly for configuration \(index)")
            XCTAssertEqual(sut.entries.count, entries.count, "Entry count should match for configuration \(index)")
            
            let expectedTotal = entries.reduce(0.0) { $0 + $1.value }
            XCTAssertEqual(sut.total(), expectedTotal, accuracy: 0.001, "Total should be correct for configuration \(index)")
        }
    }
    
    func testCarbEntryByDay_EntriesProperty_PreservesValues() {
        // Given
        let testDay = Date()
        let values = [12.5, 8.25, 15.0, 22.75]
        let entries = values.map { CarbEntry(timestamp: testDay, value: $0) }
        
        // When
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // Then
        XCTAssertEqual(sut.entries.count, values.count, "Should preserve entry count")
        for (index, entry) in sut.entries.enumerated() {
            XCTAssertEqual(entry.value, values[index], accuracy: 0.001, "Should preserve entry value at index \(index)")
            XCTAssertEqual(entry.timestamp, testDay, "Should preserve entry timestamp at index \(index)")
        }
    }
    
    func testTotal_ConsistencyAcrossMultipleCalls() {
        // Given
        let testDay = Date()
        let entries = [
            CarbEntry(timestamp: testDay, value: 7.5),
            CarbEntry(timestamp: testDay, value: 12.25),
            CarbEntry(timestamp: testDay, value: 9.75)
        ]
        let sut = CarbEntryByDay(day: testDay, entries: entries)
        
        // When
        let totals = (0..<5).map { _ in sut.total() }
        
        // Then
        let expectedTotal = 29.5
        for (index, total) in totals.enumerated() {
            XCTAssertEqual(total, expectedTotal, accuracy: 0.001, "Total should be consistent across call \(index + 1)")
        }
        
        // Verify all totals are the same
        let uniqueTotals = Set(totals.map { Int($0 * 1000) }) // Convert to avoid floating point comparison issues
        XCTAssertEqual(uniqueTotals.count, 1, "All total() calls should return the same value")
    }
}
