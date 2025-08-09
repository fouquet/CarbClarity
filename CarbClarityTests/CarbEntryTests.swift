//
//  CarbEntryTests.swift
//  CarbClarity
//
//  Created by René Fouquet on 11.07.25.
//

import XCTest
@testable import CarbClarity

final class CarbEntryByDayBasicTests: XCTestCase {
    
    // MARK: - Total Calculation Tests
    
    func testTotal_WithMultipleEntries_ReturnsCorrectSum() {
        // Given
        let testEntries = [
            CarbEntry(value: 3),
            CarbEntry(value: 2),
            CarbEntry(value: 6),
            CarbEntry(value: 10)
        ]
        let sut = CarbEntryByDay(day: Date(), entries: testEntries)
        
        // When
        let result = sut.total()
        
        // Then
        XCTAssertEqual(result, 21)
    }
}
