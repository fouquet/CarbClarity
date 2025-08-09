//
//  AppSettingsTests.swift
//  CarbClarityTests
//
//  Created by René Fouquet on 19.07.25.
//

import XCTest
@testable import CarbClarity

final class AppSettingsTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Clean up any existing test data before each test
        clearAllSettings()
    }
    
    private func clearAllSettings() {
        let testKeys = [
            AppSettings.SettingsKey.carbLimit.rawValue,
            AppSettings.SettingsKey.cautionLimit.rawValue,
            AppSettings.SettingsKey.warnLimitEnabled.rawValue,
            AppSettings.SettingsKey.cautionLimitEnabled.rawValue,
            AppSettings.SettingsKey.lookupEnabled.rawValue,
            AppSettings.SettingsKey.lookupAPIKey.rawValue,
            AppSettings.SettingsKey.quickAddButtonsEnabled.rawValue,
            AppSettings.SettingsKey.widgetLastUpdate.rawValue
        ]
        
        for key in testKeys {
            AppSettings.sharedUserDefaults?.removeObject(forKey: key)
        }
    }
    
    
    func test_allSettingKeys_AreUnique() {
        // Given
        let allKeys = [
            AppSettings.SettingsKey.carbLimit.rawValue,
            AppSettings.SettingsKey.cautionLimit.rawValue,
            AppSettings.SettingsKey.warnLimitEnabled.rawValue,
            AppSettings.SettingsKey.cautionLimitEnabled.rawValue,
            AppSettings.SettingsKey.lookupEnabled.rawValue,
            AppSettings.SettingsKey.lookupAPIKey.rawValue,
            AppSettings.SettingsKey.quickAddButtonsEnabled.rawValue,
            AppSettings.SettingsKey.widgetLastUpdate.rawValue
        ]
        
        // When
        let uniqueKeys = Set(allKeys)
        
        // Then
        XCTAssertEqual(allKeys.count, uniqueKeys.count, "All setting keys should be unique")
    }
    
      
    // MARK: - Integration Tests
    
    func test_multipleSettings_StoreIndependently() {
        // Given
        let expectedCarbLimit = 25.0
        let expectedCautionLimit = 18.0
        let expectedWarnEnabled = false
        let expectedLookupEnabled = true
        let expectedAPIKey = "test-key"
        let expectedQuickAddEnabled = true
        
        // When
        AppSettings.carbLimit = expectedCarbLimit
        AppSettings.cautionLimit = expectedCautionLimit
        AppSettings.warnLimitEnabled = expectedWarnEnabled
        AppSettings.lookupEnabled = expectedLookupEnabled
        AppSettings.lookupAPIKey = expectedAPIKey
        AppSettings.quickAddButtonsEnabled = expectedQuickAddEnabled
        
        // Then
        XCTAssertEqual(AppSettings.carbLimit, expectedCarbLimit)
        XCTAssertEqual(AppSettings.cautionLimit, expectedCautionLimit)
        XCTAssertEqual(AppSettings.warnLimitEnabled, expectedWarnEnabled)
        XCTAssertEqual(AppSettings.lookupEnabled, expectedLookupEnabled)
        XCTAssertEqual(AppSettings.lookupAPIKey, expectedAPIKey)
        XCTAssertEqual(AppSettings.quickAddButtonsEnabled, expectedQuickAddEnabled)
    }
    
      
    // MARK: - Lookup Feature Tests
    
    func test_lookupEnabled_DependsOnAPIKey() {
        // Given
        AppSettings.lookupAPIKey = ""
        AppSettings.lookupEnabled = true
        
        // When
        let enabledWithoutKey = AppSettings.lookupEnabled
        
        // Then
        XCTAssertFalse(enabledWithoutKey, "lookupEnabled should be false when API key is empty")
        
        // Given
        AppSettings.lookupAPIKey = "valid-api-key"
        AppSettings.lookupEnabled = true
        
        // When
        let enabledWithKey = AppSettings.lookupEnabled
        
        // Then
        XCTAssertTrue(enabledWithKey, "lookupEnabled should be true when API key is set")
        
        // Given
        AppSettings.lookupEnabled = false
        
        // When
        let explicitlyDisabled = AppSettings.lookupEnabled
        
        // Then
        XCTAssertFalse(explicitlyDisabled, "lookupEnabled should respect explicit false setting")
    }
    
    // MARK: - Quick Add Buttons Tests
    
    func test_quickAddButtonsEnabled_DefaultsToFalse() {
        // When & Then
        XCTAssertFalse(AppSettings.quickAddButtonsEnabled, "quickAddButtonsEnabled should default to false")
    }
    
    func test_quickAddButtonsEnabled_CanBeSetAndRetrieved() {
        // Given
        let expectedValue = true
        
        // When
        AppSettings.quickAddButtonsEnabled = expectedValue
        
        // Then
        XCTAssertEqual(AppSettings.quickAddButtonsEnabled, expectedValue, "quickAddButtonsEnabled should be settable and retrievable")
        
        // Given
        let anotherValue = false
        
        // When
        AppSettings.quickAddButtonsEnabled = anotherValue
        
        // Then
        XCTAssertEqual(AppSettings.quickAddButtonsEnabled, anotherValue, "quickAddButtonsEnabled should update when changed")
    }
    
    func test_quickAddButtonsEnabled_PersistsAcrossInstances() {
        // Given
        AppSettings.quickAddButtonsEnabled = true
        
        // When
        let retrievedValue = AppSettings.sharedUserDefaults?.bool(forKey: AppSettings.SettingsKey.quickAddButtonsEnabled.rawValue) ?? false
        
        // Then
        XCTAssertTrue(retrievedValue, "quickAddButtonsEnabled should persist in UserDefaults")
        
        XCTAssertTrue(AppSettings.quickAddButtonsEnabled, "quickAddButtonsEnabled should be accessible through AppSettings")
    }
}
