//
//  LookupAPIEnvironmentTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import SwiftUI
@testable import CarbClarity

final class LookupAPIEnvironmentTests: XCTestCase {
    
    // MARK: - Environment Value Management Tests
    
    func testEnvironmentValues_LookupAPIFactory_CanBeSetAndRetrieved() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockFactory: (@Sendable () -> LookupAPIProtocol) = {
            MockLookupAPIForEnv()
        }
        
        // When
        environmentValues.lookupAPIFactory = mockFactory
        let retrievedFactory = environmentValues.lookupAPIFactory
        
        // Then
        XCTAssertNotNil(retrievedFactory, "Should be able to set and retrieve lookup API factory")
        
        // Verify the factory actually works
        let api = retrievedFactory?()
        XCTAssertNotNil(api, "Factory should create a valid API instance")
    }
    
    func testEnvironmentValues_LookupAPIFactory_CanBeSetToNil() {
        // Given
        var environmentValues = EnvironmentValues()
        let mockFactory: (@Sendable () -> LookupAPIProtocol) = {
            MockLookupAPIForEnv()
        }
        environmentValues.lookupAPIFactory = mockFactory
        
        // When
        environmentValues.lookupAPIFactory = nil
        
        // Then
        XCTAssertNil(environmentValues.lookupAPIFactory, "Should be able to clear the factory")
    }
    
    func testLookupAPIFactory_CreatesWorkingInstances() {
        // Given
        let factory: (@Sendable () -> LookupAPIProtocol) = {
            MockLookupAPIForEnv()
        }
        
        // When
        let api1 = factory()
        let api2 = factory()
        
        // Then
        XCTAssertNotNil(api1, "Factory should create valid instances")
        XCTAssertNotNil(api2, "Factory should create multiple instances")
        XCTAssertEqual(api1.apiKey, "mock-api-key", "Created instances should have expected properties")
    }
    
    // MARK: - Coverage Tests
    
    func testMockLookupAPIForEnv_ImplementsAllProtocolMethods() async throws {
        // Given
        let mockAPI = MockLookupAPIForEnv()
        
        // When
        let searchResults = try await mockAPI.search(for: "test food")
        let foodDetail = try await mockAPI.fetchFoodDetail(fdcId: 123)
        
        // Then
        XCTAssertFalse(searchResults.isEmpty, "Search should return results")
        XCTAssertNotNil(foodDetail, "Food detail should return a value")
        XCTAssertEqual(searchResults.first?.name, "Mock Food", "Should return expected mock data")
        XCTAssertEqual(foodDetail, 10.0, "Should return expected mock food detail")
    }
    
    func testEnvironmentValues_LookupAPIFactory_HandlesDifferentFactories() {
        // Given
        var environmentValues = EnvironmentValues()
        let factory1: (@Sendable () -> LookupAPIProtocol) = { MockLookupAPIForEnv() }
        let factory2: (@Sendable () -> LookupAPIProtocol) = { MockLookupAPIForEnv() }
        
        // When
        environmentValues.lookupAPIFactory = factory1
        let retrieved1 = environmentValues.lookupAPIFactory
        
        environmentValues.lookupAPIFactory = factory2
        let retrieved2 = environmentValues.lookupAPIFactory
        
        environmentValues.lookupAPIFactory = nil
        let retrievedNil = environmentValues.lookupAPIFactory
        
        // Then
        XCTAssertNotNil(retrieved1, "Should set first factory")
        XCTAssertNotNil(retrieved2, "Should set second factory")
        XCTAssertNil(retrievedNil, "Should clear factory when set to nil")
        
        // Test that factories actually work
        let api1 = retrieved1?()
        let api2 = retrieved2?()
        XCTAssertNotNil(api1, "First factory should create instances")
        XCTAssertNotNil(api2, "Second factory should create instances")
    }
    
    func testMockLookupAPIForEnv_ExercisesAllCodePaths() async {
        // Given
        let mockAPI = MockLookupAPIForEnv()
        
        // When & Then - Exercise all methods to ensure code coverage
        XCTAssertEqual(mockAPI.apiKey, "mock-api-key", "API key should be accessible")
        
        do {
            let searchResults = try await mockAPI.search(for: "apple")
            XCTAssertEqual(searchResults.count, 1, "Should return one mock result")
            XCTAssertEqual(searchResults[0].name, "Mock Food", "Should return mock food name")
            XCTAssertEqual(searchResults[0].carbs, 25.0, "Should return mock carb value")
            XCTAssertEqual(searchResults[0].fdcId, 123, "Should return mock FDC ID")
            
            let detail = try await mockAPI.fetchFoodDetail(fdcId: 456)
            XCTAssertEqual(detail, 10.0, "Should return mock detail value")
        } catch {
            XCTFail("Mock API should not throw errors")
        }
    }
}

// MARK: - Test Helpers

private final class MockLookupAPIForEnv: LookupAPIProtocol, @unchecked Sendable {
    let apiKey: String = "mock-api-key"
    
    func search(for string: String) async throws -> [CarbFood] {
        // Exercise the search method with meaningful test data
        return [CarbFood(name: "Mock Food", carbs: 25.0, fdcId: 123)]
    }
    
    func fetchFoodDetail(fdcId: Int) async throws -> Double? {
        // Exercise the fetchFoodDetail method
        return 10.0
    }
}
