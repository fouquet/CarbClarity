//
//  QuickAddButtonsUITests.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 08.08.25.
//

import XCTest

final class QuickAddButtonsUITests: CarbClarityUITestBase {
    
    override var additionalLaunchArguments: [String] {
        return ["--enable-quick-add-buttons"]
    }
    
    // MARK: - Quick Add Buttons Visibility Tests
    
    func testQuickAddButtonsHiddenByDefault() throws {
        // Given
        app.terminate()
        app.launchArguments = ["--reset-settings"]
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 5))
        
        // Then
        XCTAssertFalse(app.staticTexts["Quick Add"].exists, "Quick Add section should be hidden when disabled")
        XCTAssertFalse(app.buttons["0.1g"].exists, "0.1g quick add button should not be visible when disabled")
        XCTAssertFalse(app.buttons["0.5g"].exists, "0.5g quick add button should not be visible when disabled")
        XCTAssertFalse(app.buttons["1g"].exists, "1g quick add button should not be visible when disabled")
    }
    
    func testQuickAddButtonsVisibleWhenEnabled() throws {
        XCTAssertTrue(app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 5))
        
        // Then
        XCTAssertTrue(app.staticTexts["Quick Add"].exists, "Quick Add section should be visible when enabled")
        XCTAssertTrue(app.buttons["0.1g"].exists, "0.1g quick add button should be visible when enabled")
        XCTAssertTrue(app.buttons["0.5g"].exists, "0.5g quick add button should be visible when enabled")
        XCTAssertTrue(app.buttons["1g"].exists, "1g quick add button should be visible when enabled")
        XCTAssertTrue(app.buttons["4g"].exists, "4g quick add button should be visible when enabled")
        XCTAssertTrue(app.buttons["6g"].exists, "6g quick add button should be visible when enabled")
        XCTAssertTrue(app.buttons["10g"].exists, "10g quick add button should be visible when enabled")
    }
    
    func testToggleQuickAddButtonsInSettings() throws {
        // Given
        app.terminate()
        app.launchArguments = ["--reset-settings"]
        app.launch()
        
        XCTAssertTrue(app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Quick Add"].exists)
        
        // When
        app.buttons["Settings"].tap()
        let quickAddToggle = app.switches["Quick Add Buttons Enabled"]
        XCTAssertTrue(quickAddToggle.exists, "Quick Add Buttons toggle should exist in settings")
        XCTAssertFalse(quickAddToggle.isOn, "Quick Add Buttons toggle should be off initially")
        
        quickAddToggle.tap()
        XCTAssertTrue(quickAddToggle.isOn, "Quick Add Buttons toggle should be on after tapping")
        
        app.tapNavigationDone()
        
        // Then
        XCTAssertTrue(app.staticTexts["Quick Add"].waitForExistence(timeout: 2), "Quick Add section should appear after enabling")
        XCTAssertTrue(app.buttons["0.1g"].exists, "0.1g button should be visible after enabling")
        XCTAssertTrue(app.buttons["10g"].exists, "10g button should be visible after enabling")
        
        // When
        app.buttons["Settings"].tap()
        let quickAddToggleAgain = app.switches["Quick Add Buttons Enabled"]
        XCTAssertTrue(quickAddToggleAgain.isOn, "Toggle should remain on")
        quickAddToggleAgain.tap()
        XCTAssertFalse(quickAddToggleAgain.isOn, "Toggle should be off after second tap")
        
        app.tapNavigationDone()
        
        // Then
        XCTAssertFalse(app.staticTexts["Quick Add"].exists, "Quick Add section should be hidden after disabling")
        XCTAssertFalse(app.buttons["0.1g"].exists, "Quick add buttons should be hidden after disabling")
    }
    
    // MARK: - Quick Add Button Functionality Tests
    
    func testQuickAddButtonAddsCorrectValue() throws {
        // Given
        verifyMainScreenLoaded()
        XCTAssertTrue(app.staticTexts["Quick Add"].exists, "Quick add buttons should be visible")
        XCTAssertTrue(app.staticTexts["0g"].exists || app.staticTexts["0.0g"].exists || app.staticTexts["0"].exists)
        
        // When
        let oneGramButton = app.buttons["1g"]
        XCTAssertTrue(oneGramButton.exists, "1g button should exist")
        oneGramButton.tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["1g"].waitForExistence(timeout: 3), "Total should show 1g after adding 1g")
        XCTAssertTrue(app.staticTexts["1g"].exists, "1g entry should appear in history")
    }
    
    func testMultipleQuickAddButtons() throws {
        // Given
        verifyMainScreenLoaded()
        
        // When
        app.buttons["0.5g"].tap()
        app.buttons["2g"].exists ? app.buttons["2g"].tap() : app.buttons["1g"].tap()
        app.buttons["4g"].tap()
        
        // Then
        // 0.5 + 1 + 4 = 5.5 (or if 2g exists: 0.5 + 2 + 4 = 6.5)
        let expectedTotal = app.buttons["2g"].exists ? "6.5g" : "5.5g"
        XCTAssertTrue(app.staticTexts[expectedTotal].waitForExistence(timeout: 3), "Total should show correct sum")
        XCTAssertTrue(app.staticTexts["0.5g"].exists, "0.5g entry should appear in history")
        XCTAssertTrue(app.staticTexts["4g"].exists, "4g entry should appear in history")
    }
    
    func testAllPresetQuickAddValues() throws {
        // Given
        verifyMainScreenLoaded()
        let presetValues = ["0.1g", "0.5g", "1g", "4g", "6g", "10g"]
        
        var expectedTotal = 0.0
        
        for valueString in presetValues {
            // When
            let button = app.buttons[valueString]
            XCTAssertTrue(button.exists, "\(valueString) button should exist")
            button.tap()
            let numericValue = Double(valueString.dropLast()) ?? 0.0
            expectedTotal += numericValue
            
            // Then
            XCTAssertTrue(app.staticTexts[valueString].exists, "\(valueString) entry should appear in history")
        }
        let totalString = String(format: "%.1fg", expectedTotal).replacingOccurrences(of: ".0g", with: "g")
        XCTAssertTrue(app.staticTexts[totalString].exists || app.staticTexts["21.6g"].exists, "Final total should be correct")
    }
    
    func testQuickAddButtonsWithManualEntry() throws {
        // Given
        verifyMainScreenLoaded()
        
        // When
        app.buttons["2g"].exists ? app.buttons["2g"].tap() : app.buttons["1g"].tap()
        let textField = app.textFields["New carbs in grams"]
        textField.tap()
        textField.typeText("7.5")
        
        if app.keyboards.firstMatch.exists {
            app.tapKeyboardDone()
        }
        
        app.buttons["Add"].tap()
        app.buttons["4g"].tap()
        
        // Then
        // 1 + 7.5 + 4 = 12.5 (or if 2g exists: 2 + 7.5 + 4 = 13.5)
        let expectedTotal = app.buttons["2g"].exists ? "13.5g" : "12.5g"
        XCTAssertTrue(app.staticTexts[expectedTotal].waitForExistence(timeout: 3), "Total should include both quick add and manual entries")
        XCTAssertTrue(app.staticTexts["7.5g"].exists, "Manual entry should appear")
        XCTAssertTrue(app.staticTexts["4g"].exists, "Quick add entry should appear")
    }
    
    // MARK: - Quick Add Buttons Layout Tests
    
    func testQuickAddButtonsLayout() throws {
        // Given
        verifyMainScreenLoaded()
        XCTAssertTrue(app.staticTexts["Quick Add"].exists)
        
        // Then
        let expectedButtons = ["0.1g", "0.5g", "1g", "4g", "6g", "10g"]
        
        for buttonLabel in expectedButtons {
            let button = app.buttons[buttonLabel]
            XCTAssertTrue(button.exists, "\(buttonLabel) button should exist")
            XCTAssertTrue(button.isHittable, "\(buttonLabel) button should be tappable")
        }
        XCTAssertTrue(app.staticTexts["Quick Add"].exists, "Quick Add section title should be visible")
    }
    
    func testQuickAddButtonsAccessibility() throws {
        // Given
        verifyMainScreenLoaded()
        
        // Then
        let expectedButtons = ["0.1g", "0.5g", "1g", "4g", "6g", "10g"]
        
        for buttonLabel in expectedButtons {
            let button = app.buttons[buttonLabel]
            XCTAssertTrue(button.exists, "\(buttonLabel) button should exist")
            XCTAssertTrue(button.isHittable, "\(buttonLabel) button should be accessible")
            XCTAssertEqual(button.label, buttonLabel, "\(buttonLabel) button should have correct accessibility label")
        }
    }
    
    // MARK: - Quick Add Buttons with Limits Tests
    
    func testQuickAddButtonsWithCarbLimitWarning() throws {
        // Given
        app.buttons["Settings"].tap()
        
        let warningSwitch = app.switches["Warning limit enabled"]
        if !warningSwitch.isOn {
            warningSwitch.tap()
        }
        
        let limitTextField = app.textFields["Warning Limit"]
        limitTextField.tap()
        limitTextField.clearText()
        limitTextField.typeText("5")
        
        app.tapNavigationDone()
        
        // When
        app.buttons["6g"].tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].waitForExistence(timeout: 3), "Carb limit warning should appear")
        XCTAssertTrue(app.staticTexts["6g"].exists, "Total should show 6g")
    }
    
    // MARK: - Performance Tests
    
    func testQuickAddButtonsPerformance() throws {
        // Given
        verifyMainScreenLoaded()
        
        // When
        measure {
            for _ in 1...5 {
                app.buttons["1g"].tap()
                usleep(100000)
            }
        }
        
        // Then
        XCTAssertTrue(app.staticTexts["5g"].waitForExistence(timeout: 3), "Total should show 5g after 5 quick additions")
    }
    
    // MARK: - Settings Integration Tests
    
    func testQuickAddButtonsSettingsPersistence() throws {
        // Given
        app.buttons["Settings"].tap()
        
        let quickAddToggle = app.switches["Quick Add Buttons Enabled"]
        if !quickAddToggle.isOn {
            quickAddToggle.tap()
        }
        
        app.tapNavigationDone()
        XCTAssertTrue(app.staticTexts["Quick Add"].waitForExistence(timeout: 2))
        
        // When
        app.buttons["Settings"].tap()
        
        // Then
        let persistedToggle = app.switches["Quick Add Buttons Enabled"]
        XCTAssertTrue(persistedToggle.isOn, "Quick Add Buttons setting should persist")
        
        app.tapNavigationDone()
        XCTAssertTrue(app.staticTexts["Quick Add"].exists, "Quick Add buttons should remain visible")
    }
    
    func testQuickAddButtonsSettingsDescription() throws {
        // When
        app.buttons["Settings"].tap()
        
        // Then
        XCTAssertTrue(app.staticTexts["Show Quick Add Buttons"].exists, "Quick Add setting label should exist")
        let hasDescriptiveText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'preset buttons'")).count > 0 ||
                                app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'quickly adding'")).count > 0
        XCTAssertTrue(hasDescriptiveText, "Settings should include descriptive text about quick add buttons")
        
        app.tapNavigationDone()
    }
}
