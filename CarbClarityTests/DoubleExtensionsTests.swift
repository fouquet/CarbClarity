//
//  DoubleExtensionsTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 17.07.25.
//

import XCTest
@testable import CarbClarity

final class DoubleExtensionsTests: XCTestCase {
    
    // MARK: - carbString() Tests
    
    func testCarbString_WithWholeNumbers_ReturnsFormattedString() {
        // Given & When & Then
        XCTAssertEqual(1.0.carbString(), "1g")
        XCTAssertEqual(5.0.carbString(), "5g")
        XCTAssertEqual(10.0.carbString(), "10g")
        XCTAssertEqual(25.0.carbString(), "25g")
    }
    
    func testCarbString_WithDecimalValues_ReturnsFormattedString() {
        XCTAssertEqual(1.5.carbString(), "1.5g")
        XCTAssertEqual(12.25.carbString(), "12.25g")
        XCTAssertEqual(5.75.carbString(), "5.75g")
        XCTAssertEqual(0.5.carbString(), "0.5g")
    }
    
    func testCarbString_WithRoundingToTwoDecimalPlaces_ReturnsRoundedString() {
        // Given
        let valueWithThreeDecimals = 12.555
        let valueWithFourDecimals = 12.554
        let valueRoundingToWhole = 0.999
        let smallRoundingValue = 5.001
        
        // When & Then
        XCTAssertEqual(valueWithThreeDecimals.carbString(), "12.56g")
        XCTAssertEqual(valueWithFourDecimals.carbString(), "12.55g")
        XCTAssertEqual(valueRoundingToWhole.carbString(), "1g")
        XCTAssertEqual(smallRoundingValue.carbString(), "5g")
    }
    
    func testCarbString_WithVerySmallNumbers_ReturnsCorrectFormat() {
        XCTAssertEqual(0.1.carbString(), "0.1g")
        XCTAssertEqual(0.01.carbString(), "0.01g")
        XCTAssertEqual(0.001.carbString(), "0g")
        XCTAssertEqual(0.005.carbString(), "0.01g")
    }
    
    func testCarbString_WithLargeNumbers_ReturnsFormattedString() {
        XCTAssertEqual(100.0.carbString(), "100g")
        XCTAssertEqual(999.99.carbString(), "999.99g")
        XCTAssertEqual(1000.5.carbString(), "1000.5g")
    }
    
    func testCarbString_WithZero_ReturnsZeroGrams() {
        XCTAssertEqual(0.0.carbString(), "0g")
    }
    
    func testCarbString_WithNegativeNumbers_ReturnsFormattedNegativeString() {
        XCTAssertEqual((-1.0).carbString(), "-1g")
        XCTAssertEqual((-5.25).carbString(), "-5.25g")
        XCTAssertEqual((-0.5).carbString(), "-0.5g")
    }
    
    
    // MARK: - roundedForCarbs() Tests
    
    func testRoundedForCarbs_WithBasicRounding_ReturnsRoundedValue() {
        // Given & When & Then
        XCTAssertEqual(12.555.roundedForCarbs(), 12.56)
        XCTAssertEqual(12.554.roundedForCarbs(), 12.55)
        XCTAssertEqual(12.545.roundedForCarbs(), 12.55)
        XCTAssertEqual(12.535.roundedForCarbs(), 12.54)
    }
    
    
    func testRoundedForCarbs_WithThreeDecimalPlaces_ReturnsRoundedToTwo() {
        XCTAssertEqual(5.123.roundedForCarbs(), 5.12)
        XCTAssertEqual(5.126.roundedForCarbs(), 5.13)
        XCTAssertEqual(5.125.roundedForCarbs(), 5.13)
        XCTAssertEqual(5.135.roundedForCarbs(), 5.14)
    }
    
    func testRoundedForCarbs_WithVerySmallNumbers_ReturnsCorrectPrecision() {
        XCTAssertEqual(0.001.roundedForCarbs(), 0.0)
        XCTAssertEqual(0.005.roundedForCarbs(), 0.01)
        XCTAssertEqual(0.009.roundedForCarbs(), 0.01)
        XCTAssertEqual(0.004.roundedForCarbs(), 0.0)
    }
    
    func testRoundedForCarbs_WithLargeNumbers_ReturnsRoundedValue() {
        XCTAssertEqual(999.999.roundedForCarbs(), 1000.0)
        XCTAssertEqual(1000.555.roundedForCarbs(), 1000.56)
        XCTAssertEqual(123.456.roundedForCarbs(), 123.46)
    }
    
    func testRoundedForCarbs_WithZeroAndNearZero_ReturnsCorrectValue() {
        XCTAssertEqual(0.0.roundedForCarbs(), 0.0)
        XCTAssertEqual(0.001.roundedForCarbs(), 0.0)
        XCTAssertEqual(0.004.roundedForCarbs(), 0.0)
    }
    
    func testRoundedForCarbs_WithNegativeNumbers_ReturnsRoundedNegativeValue() {
        XCTAssertEqual((-5.123).roundedForCarbs(), -5.12)
        XCTAssertEqual((-5.126).roundedForCarbs(), -5.13)
        XCTAssertEqual((-0.005).roundedForCarbs(), -0.01)
    }
    
    // MARK: - Integration Tests
    
    func testCarbString_UsesRoundedValues_ConsistentOutput() {
        // Given
        let testValue = 12.555
        let expectedString = "12.56g"
        
        // When
        let directString = testValue.carbString()
        let roundedString = testValue.roundedForCarbs().carbString()
        
        // Then
        XCTAssertEqual(directString, expectedString)
        XCTAssertEqual(roundedString, expectedString)
    }
    
    func testRoundedForCarbs_DoesNotAffectDisplay_WhenAlreadyRounded() {
        let testValue = 12.56
        
        let rounded = testValue.roundedForCarbs()
        let originalString = testValue.carbString()
        let roundedString = rounded.carbString()
        
        XCTAssertEqual(testValue, rounded)
        XCTAssertEqual(originalString, roundedString)
    }
    
    func testConsistencyBetweenRoundingAndDisplay_WithMultipleValues_ProducesSameOutput() {
        let testValues = [0.0, 0.1, 0.55, 1.0, 5.123, 12.555, 99.999]
        
        for value in testValues {
            let rounded = value.roundedForCarbs()
            let directString = value.carbString()
            let roundedString = rounded.carbString()
            
            XCTAssertEqual(directString, roundedString, "Value: \(value)")
        }
    }
    
}
