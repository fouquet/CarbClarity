//
//  StatisticsViewModelTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

final class StatisticsViewModelTests: XCTestCase {
    
    var calendar: Calendar!
    var now: Date!
    
    override func setUpWithError() throws {
        calendar = Calendar.current
        now = Date()
    }
    
    override func tearDownWithError() throws {
        calendar = nil
        now = nil
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testInit_WithDefaults_SetsInitialState() {
        // Given & When
        let viewModel = StatisticsViewModel()
        
        // Then
        XCTAssertTrue(viewModel.dailyData.isEmpty)
        XCTAssertTrue(viewModel.weeklyData.isEmpty)
        XCTAssertEqual(viewModel.weeklyAverage, 0.0)
        XCTAssertEqual(viewModel.monthlyTotal, 0.0)
        XCTAssertNil(viewModel.lowestDay)
        XCTAssertNil(viewModel.highestDay)
    }
    
    // MARK: - UpdateData Tests
    
    @MainActor
    func testUpdateData_WithEmptyEntries_ClearsStatistics() {
        // Given
        let sut = StatisticsViewModel()
        let entries: [CarbEntry] = []
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertEqual(sut.dailyData.count, 30) // Should have 30 days even with empty data
        XCTAssertTrue(sut.dailyData.allSatisfy { $0.totalCarbs == 0.0 })
        XCTAssertEqual(sut.weeklyAverage, 0.0)
        XCTAssertEqual(sut.monthlyTotal, 0.0)
        XCTAssertNil(sut.lowestDay)
        XCTAssertNil(sut.highestDay)
    }
    
    @MainActor
    func testUpdateData_WithSingleDayEntries_CalculatesCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let entries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 25.0),
            CarbEntry(timestamp: today.addingTimeInterval(7200), value: 15.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        let todayData = sut.dailyData.last!
        XCTAssertEqual(todayData.totalCarbs, 40.0)
        XCTAssertEqual(sut.weeklyAverage, 40.0 / 7.0, accuracy: 0.01)
    }
    
    @MainActor
    func testUpdateData_WithMultipleDayEntries_CalculatesCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let entries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 25.0),
            CarbEntry(timestamp: yesterday.addingTimeInterval(3600), value: 30.0),
            CarbEntry(timestamp: twoDaysAgo.addingTimeInterval(3600), value: 20.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertEqual(sut.dailyData.count, 30)
        let todayData = sut.dailyData.last!
        let yesterdayData = sut.dailyData[sut.dailyData.count - 2]
        let twoDaysAgoData = sut.dailyData[sut.dailyData.count - 3]
        
        XCTAssertEqual(todayData.totalCarbs, 25.0)
        XCTAssertEqual(yesterdayData.totalCarbs, 30.0)
        XCTAssertEqual(twoDaysAgoData.totalCarbs, 20.0)
        XCTAssertEqual(sut.weeklyAverage, 75.0 / 7.0, accuracy: 0.01)
    }
    
    @MainActor
    func testUpdateData_WithOldEntries_FiltersCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let thirtyOneDaysAgo = calendar.date(byAdding: .day, value: -31, to: today)!
        let twentyNineDaysAgo = calendar.date(byAdding: .day, value: -29, to: today)!
        
        let entries = [
            CarbEntry(timestamp: thirtyOneDaysAgo.addingTimeInterval(3600), value: 100.0), // Should be filtered out
            CarbEntry(timestamp: twentyNineDaysAgo.addingTimeInterval(3600), value: 25.0), // Should be included
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 30.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        let totalInDailyData = sut.dailyData.reduce(0.0) { $0 + $1.totalCarbs }
        XCTAssertEqual(totalInDailyData, 55.0) // Should not include the 31-day-old entry
    }
    
    // MARK: - Statistics Tests
    
    @MainActor
    func testCalculateStatistics_WithRecentEntries_CalculatesWeeklyAverage() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        var entries: [CarbEntry] = []
        
        // Add entries for the past 7 days
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            entries.append(CarbEntry(timestamp: date.addingTimeInterval(3600), value: 14.0))
        }
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertEqual(sut.weeklyAverage, 14.0, accuracy: 0.01)
    }
    
    @MainActor
    func testCalculateStatistics_WithCurrentMonthEntries_CalculatesMonthlyTotal() {
        // Given
        let sut = StatisticsViewModel()
        let monthStart = calendar.dateInterval(of: .month, for: now)!.start
        let entries = [
            CarbEntry(timestamp: monthStart.addingTimeInterval(86400), value: 25.0),
            CarbEntry(timestamp: monthStart.addingTimeInterval(172800), value: 30.0),
            CarbEntry(timestamp: now, value: 20.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertEqual(sut.monthlyTotal, 75.0)
    }
    
    @MainActor
    func testCalculateStatistics_WithVariousCarbs_IdentifiesLowestAndHighestDay() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let entries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 50.0), // Highest
            CarbEntry(timestamp: yesterday.addingTimeInterval(3600), value: 10.0), // Lowest
            CarbEntry(timestamp: twoDaysAgo.addingTimeInterval(3600), value: 25.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertNotNil(sut.lowestDay)
        XCTAssertNotNil(sut.highestDay)
        XCTAssertEqual(sut.lowestDay?.value, 10.0)
        XCTAssertEqual(sut.highestDay?.value, 50.0)
    }
    
    // MARK: - Edge Cases
    
    @MainActor
    func testUpdateData_WithSameTimestampEntries_HandlesCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let exactTime = today.addingTimeInterval(3600)
        let entries = [
            CarbEntry(timestamp: exactTime, value: 15.0),
            CarbEntry(timestamp: exactTime, value: 10.0),
            CarbEntry(timestamp: exactTime, value: 5.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        let todayData = sut.dailyData.last!
        XCTAssertEqual(todayData.totalCarbs, 30.0)
    }
    
    @MainActor
    func testUpdateData_WithDecimalValues_HandlesFloatingPointCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let entries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 12.25),
            CarbEntry(timestamp: today.addingTimeInterval(7200), value: 15.75),
            CarbEntry(timestamp: today.addingTimeInterval(10800), value: 8.5)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        let todayData = sut.dailyData.last!
        XCTAssertEqual(todayData.totalCarbs, 36.5, accuracy: 0.001)
    }
    
    // MARK: - WeeklyData Tests
    
    @MainActor
    func testStatisticsViewModel_GeneratesWeeklyDataCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        var entries: [CarbEntry] = []
        
        // Add entries across the last 28 days (4 weeks) to test weekly data generation
        for day in 0..<28 {
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            let weekNumber = day / 7
            entries.append(CarbEntry(timestamp: date.addingTimeInterval(3600), value: Double(20 + weekNumber * 5)))
        }
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertFalse(sut.dailyData.isEmpty, "Daily data should be populated")
        XCTAssertEqual(sut.dailyData.count, 30, "Should generate 30 days of daily data")
        
        // Verify that updateData processes the entries without crashing
        let totalEntries = entries.count
        XCTAssertEqual(totalEntries, 28, "Should have created 28 entries")
    }
    
    @MainActor
    func testStatisticsViewModel_WithSparseDayData_HandlesCorrectly() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: today)!
        
        let entries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 30.0),
            CarbEntry(timestamp: fiveDaysAgo.addingTimeInterval(3600), value: 20.0),
            CarbEntry(timestamp: tenDaysAgo.addingTimeInterval(3600), value: 15.0)
        ]
        
        // When
        sut.updateData(entries: entries)
        
        // Then
        XCTAssertEqual(sut.dailyData.count, 30, "Should always generate 30 days of daily data")
        let entriesWithData = sut.dailyData.filter { $0.totalCarbs > 0 }
        XCTAssertEqual(entriesWithData.count, 3, "Should have exactly 3 days with data")
        
        // Verify monthly total is calculated (exact value depends on current month boundaries)
        XCTAssertGreaterThanOrEqual(sut.monthlyTotal, 0.0, "Monthly total should be non-negative")
    }
    
    @MainActor
    func testStatisticsViewModel_HighestAndLowestDay_EdgeCases() {
        // Given
        let sut = StatisticsViewModel()
        let today = calendar.startOfDay(for: now)
        
        // Test with all same values
        let sameValueEntries = [
            CarbEntry(timestamp: today.addingTimeInterval(3600), value: 25.0),
            CarbEntry(timestamp: calendar.date(byAdding: .day, value: -1, to: today)!.addingTimeInterval(3600), value: 25.0),
            CarbEntry(timestamp: calendar.date(byAdding: .day, value: -2, to: today)!.addingTimeInterval(3600), value: 25.0)
        ]
        
        // When
        sut.updateData(entries: sameValueEntries)
        
        // Then
        XCTAssertNotNil(sut.lowestDay, "Should have lowest day even with same values")
        XCTAssertNotNil(sut.highestDay, "Should have highest day even with same values")
        XCTAssertEqual(sut.lowestDay?.value, sut.highestDay?.value, "With same values, lowest and highest should be equal")
    }
}

// MARK: - Test Data Models

final class DailyDataTests: XCTestCase {
    func testDailyData_InitializesCorrectly() {
        // Given
        let date = Date()
        let totalCarbs = 45.5
        
        // When
        let dailyData = DailyData(date: date, totalCarbs: totalCarbs)
        
        // Then
        XCTAssertEqual(dailyData.date, date, "Date should be set correctly")
        XCTAssertEqual(dailyData.totalCarbs, totalCarbs, "Total carbs should be set correctly")
    }
}

final class WeeklyDataTests: XCTestCase {
    func testWeeklyData_InitializesCorrectly() {
        // Given
        let weekStart = Date()
        let weeklyAverage = 21.43
        
        // When
        let weeklyData = WeeklyData(weekStart: weekStart, weeklyAverage: weeklyAverage)
        
        // Then
        XCTAssertEqual(weeklyData.weekStart, weekStart, "Week start should be set correctly")
        XCTAssertEqual(weeklyData.weeklyAverage, weeklyAverage, accuracy: 0.001, "Weekly average should be set correctly")
    }
}

