//
//  SettingsViewModelTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 13.07.25.
//

import XCTest
@testable import CarbClarity

@MainActor
final class SettingsViewModelTests: XCTestCase, @unchecked Sendable {
    
    var sut: SettingsViewModel!
    
    override func setUpWithError() throws {
        MainActor.assumeIsolated {
            sut = SettingsViewModel()
        }
    }

    override func tearDownWithError() throws {
        MainActor.assumeIsolated {
            sut = nil
        }
    }
    
    
    func testAppInformation_OnInit_ReturnsValidAppData() {
        // Given
        // sut is initialized in setUp
        
        // When & Then
        XCTAssertFalse(sut.appVersion.isEmpty)
        XCTAssertFalse(sut.buildNumber.isEmpty)
        XCTAssertEqual(sut.aboutText, "Carb Clarity")
        XCTAssertEqual(sut.copyrightText, "©️ 2024–2025 René Fouquet")
        XCTAssertTrue(sut.supportText.contains("support@fouquet.me"))
    }
    
    
    // MARK: - Lookup Toggle Tests
    
    func testToggleLookupEnabled_WithValidAPIKeyAndEnable_EnablesLookupAndHidesAlert() {
        sut.lookupAPIKey = "valid-key"
        
        sut.toggleLookupEnabled(true)
        
        XCTAssertTrue(sut.lookupEnabled)
        XCTAssertFalse(sut.showingAPIKeyAlert)
    }
    
    func testToggleLookupEnabled_WithEmptyAPIKeyAndEnable_DisablesLookupAndShowsAlert() {
        sut.lookupAPIKey = ""
        
        sut.toggleLookupEnabled(true)
        
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertTrue(sut.showingAPIKeyAlert)
    }
    
    func testToggleLookupEnabled_WithWhitespaceAPIKeyAndEnable_DisablesLookupAndShowsAlert() {
        sut.lookupAPIKey = "   \t\n   "
        
        sut.toggleLookupEnabled(true)
        
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertTrue(sut.showingAPIKeyAlert)
    }
    
    func testToggleLookupEnabled_WithDisable_DisablesLookupAndHidesAlert() {
        sut.lookupEnabled = true
        sut.lookupAPIKey = ""
        
        sut.toggleLookupEnabled(false)
        
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertFalse(sut.showingAPIKeyAlert)
    }
    
    func testToggleLookupEnabled_WithExistingAPIKeyAndEnable_EnablesLookupAndHidesAlert() {
        sut.lookupAPIKey = "existing-key"
        sut.lookupEnabled = false
        
        sut.toggleLookupEnabled(true)
        
        XCTAssertTrue(sut.lookupEnabled)
        XCTAssertFalse(sut.showingAPIKeyAlert)
    }
    
    
    
    // MARK: - Settings Management Tests
    
    func testUpdateSettings_WithValidValues_UpdatesAllProperties() {
        let expectedCarbLimit = 30.0
        let expectedCautionLimit = 25.0
        let expectedAPIKey = "test-key"
        
        sut.updateSettings(
            carbLimit: expectedCarbLimit,
            cautionLimit: expectedCautionLimit,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: true,
            lookupAPIKey: expectedAPIKey
        )
        
        XCTAssertEqual(sut.carbLimit, expectedCarbLimit)
        XCTAssertEqual(sut.cautionLimit, expectedCautionLimit)
        XCTAssertTrue(sut.lookupEnabled)
        XCTAssertEqual(sut.lookupAPIKey, expectedAPIKey)
    }
    
    func testUpdateSettings_WithZeroLimitAndEmptyKey_UpdatesCorrectly() {
        let expectedCarbLimit = 0.0
        let expectedCautionLimit = 0.0
        let expectedAPIKey = ""
        
        sut.updateSettings(
            carbLimit: expectedCarbLimit,
            cautionLimit: expectedCautionLimit,
            warnLimitEnabled: false,
            cautionLimitEnabled: false,
            lookupEnabled: false,
            lookupAPIKey: expectedAPIKey
        )
        
        XCTAssertEqual(sut.carbLimit, expectedCarbLimit)
        XCTAssertEqual(sut.cautionLimit, expectedCautionLimit)
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertEqual(sut.lookupAPIKey, expectedAPIKey)
    }
    
    
    // MARK: - Complex State Management Tests
    
    func testMultipleToggleOperations_WithVariousAPIKeyStates_BehavesCorrectly() {
        sut.lookupAPIKey = "valid-key"
        
        // When
        sut.toggleLookupEnabled(true)
        
        XCTAssertTrue(sut.lookupEnabled)
        
        // When
        sut.toggleLookupEnabled(false)
        
        XCTAssertFalse(sut.lookupEnabled)
        
        // When
        sut.lookupAPIKey = ""
        sut.toggleLookupEnabled(true)
        
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertTrue(sut.showingAPIKeyAlert)
    }
    
    func testComplexSettingsWorkflow_ThroughMultipleOperations_MaintainsConsistentState() {
        // Given - Start with defaults
        XCTAssertEqual(sut.carbLimit, 20.0)
        XCTAssertFalse(sut.lookupEnabled)
        
        // When - Update settings
        sut.updateSettings(
            carbLimit: 25.0,
            cautionLimit: 20.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: false,
            lookupAPIKey: ""
        )
        
        XCTAssertEqual(sut.carbLimit, 25.0)
        
        // When
        sut.toggleLookupEnabled(true)
        
        XCTAssertFalse(sut.lookupEnabled)
        XCTAssertTrue(sut.showingAPIKeyAlert)
        
        // When
        sut.lookupAPIKey = "valid-key"
        sut.dismissAPIKeyAlert()
        sut.toggleLookupEnabled(true)
        
        XCTAssertTrue(sut.lookupEnabled)
        XCTAssertFalse(sut.showingAPIKeyAlert)
        
    }
    
    // MARK: - Edge Case Tests
    
    func testUpdateSettings_WithVeryLargeCarbLimit_HandlesCorrectly() {
        let largeCarbLimit = 999.99
        let largeCautionLimit = 800.0
        
        sut.updateSettings(
            carbLimit: largeCarbLimit,
            cautionLimit: largeCautionLimit,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: false,
            lookupAPIKey: ""
        )
        
        XCTAssertEqual(sut.carbLimit, largeCarbLimit)
    }
    
    func testUpdateSettings_WithVeryLongAPIKey_HandlesCorrectly() {
        let longKey = String(repeating: "a", count: 1000)
        
        sut.updateSettings(
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: false,
            lookupAPIKey: longKey
        )
        
        XCTAssertEqual(sut.lookupAPIKey, longKey)
        XCTAssertFalse(sut.isAPIKeyEmpty)
    }
    
    func testUpdateSettings_WithSpecialCharactersInAPIKey_HandlesCorrectly() {
        let specialKey = "key-with-!@#$%^&*()_+{}[]|;':,.<>?"
        
        sut.updateSettings(
            carbLimit: 20.0,
            cautionLimit: 15.0,
            warnLimitEnabled: true,
            cautionLimitEnabled: true,
            lookupEnabled: false,
            lookupAPIKey: specialKey
        )
        
        XCTAssertEqual(sut.lookupAPIKey, specialKey)
    }
}
