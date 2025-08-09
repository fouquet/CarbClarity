//
//  AppDependencyManagerTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest
import SwiftData
@testable import CarbClarity

final class AppDependencyManagerTests: XCTestCase {
    
    // MARK: - Model Container Management Tests
    
    @MainActor
    func testSetModelContainer_UpdatesModelContainer() throws {
        // Given
        let sut = AppDependencyManager.shared
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let originalContainer = sut.modelContainer
        
        // When
        sut.setModelContainer(testContainer)
        
        // Then
        XCTAssertNotNil(sut.modelContainer, "Model container should be set")
        XCTAssertTrue(sut.modelContainer === testContainer, "Should set the correct container")
        
        sut.setModelContainer(originalContainer)
    }
    
    @MainActor
    func testSetModelContainer_ToNil_ClearsModelContainer() throws {
        // Given
        let sut = AppDependencyManager.shared
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let originalContainer = sut.modelContainer
        sut.setModelContainer(testContainer)
        XCTAssertNotNil(sut.modelContainer, "Container should be set")
        
        // When
        sut.setModelContainer(nil)
        
        // Then
        XCTAssertNil(sut.modelContainer, "Model container should be cleared")
        
        sut.setModelContainer(originalContainer)
    }
    
    @MainActor
    func testModelContainerPersistence_AcrossMultipleAccesses() throws {
        // Given
        let sut = AppDependencyManager.shared
        let schema = Schema([CarbEntry.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let testContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let originalContainer = sut.modelContainer
        
        // When
        sut.setModelContainer(testContainer)
        let retrievedContainer1 = sut.modelContainer
        let retrievedContainer2 = sut.modelContainer
        
        // Then
        XCTAssertTrue(retrievedContainer1 === testContainer, "First retrieval should return same container")
        XCTAssertTrue(retrievedContainer2 === testContainer, "Second retrieval should return same container")
        XCTAssertTrue(retrievedContainer1 === retrievedContainer2, "Multiple retrievals should return same instance")
        
        sut.setModelContainer(originalContainer)
    }
}
