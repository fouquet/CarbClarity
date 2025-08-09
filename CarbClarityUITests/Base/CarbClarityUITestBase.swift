//
//  CarbClarityUITestBase.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 15.07.25.
//

import XCTest

/// Base class for all CarbClarity UI tests providing common setup and helper methods

@MainActor
class CarbClarityUITestBase: XCTestCase {

    var app: XCUIApplication!

    var defaultLaunchArguments: [String] {
        return ["--reset-settings"]
    }

    var additionalLaunchArguments: [String] {
        return []
    }

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Ensure clean start for each test
        app.launchArguments = defaultLaunchArguments + additionalLaunchArguments
        app.launch()

        // Wait for app to fully load
        _ = app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 5)
    }

    override func tearDown() async throws {
        // Terminate the app to ensure clean state for next test
        app.terminate()
        app = nil
    }

    // MARK: - Helper Methods

    /// Launches the app with custom arguments (useful for specific test scenarios)
    func launchAppWithArguments(_ arguments: [String]) {
        app.terminate()
        app.launchArguments = arguments
        app.launch()
    }

    /// Verifies that the main screen has loaded successfully
    func verifyMainScreenLoaded() {
        // First ensure we're on the Track tab
        navigateToTrackTab()

        XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
        XCTAssertTrue(app.textFields["New carbs in grams"].exists)
        XCTAssertTrue(app.buttons["Add"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    /// Navigates to the Track tab
    func navigateToTrackTab() {
        // First try traditional tab bar approach
        if app.tabBars.firstMatch.exists {
            let tabBar = app.tabBars.firstMatch
            if tabBar.buttons["Track"].exists {
                tabBar.buttons["Track"].tap()
                return
            } else if tabBar.staticTexts["Track"].exists {
                tabBar.staticTexts["Track"].tap()
                return
            }
        }

        // If no tab bar found, try finding Track elements anywhere in the app
        let trackButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Track'"))
        if trackButtons.count > 0 {
            trackButtons.firstMatch.tap()
            return
        }

        let trackTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Track'"))
        if trackTexts.count > 0 {
            trackTexts.firstMatch.tap()
            return
        }

        // If we can't find tabs, we might already be on the Track tab
        // Just verify we can see the expected Track tab content
        _ = app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 2)
    }

    /// Navigates to the Insights tab
    func navigateToInsightsTab() {
        // First try traditional tab bar approach
        if app.tabBars.firstMatch.exists {
            let tabBar = app.tabBars.firstMatch
            if tabBar.buttons["Insights"].exists {
                tabBar.buttons["Insights"].tap()
                return
            } else if tabBar.staticTexts["Insights"].exists {
                tabBar.staticTexts["Insights"].tap()
                return
            }
        }

        // If no tab bar found, try finding Insights elements anywhere in the app
        let insightsButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Insights'"))
        if insightsButtons.count > 0 {
            insightsButtons.firstMatch.tap()
            return
        }

        let insightsTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Insights'"))
        if insightsTexts.count > 0 {
            insightsTexts.firstMatch.tap()
            return
        }

        // If we can't navigate to Insights tab, skip the test for now
        print("Warning: Could not find Insights tab - tab navigation may not be accessible to UI tests")
    }

    /// Verifies that the Insights screen has loaded successfully
    func verifyInsightsScreenLoaded() {
        navigateToInsightsTab()
        XCTAssertTrue(app.navigationBars.staticTexts["Insights"].exists)
        XCTAssertTrue(app.staticTexts["7-Day Average"].exists)
        XCTAssertTrue(app.staticTexts["This Month"].exists)
    }

    /// Navigates to the Settings screen
    func navigateToSettings() {
        navigateToTrackTab()
        app.buttons["Settings"].tap()
    }

    /// Navigates back from Settings to the main screen
    func navigateBackFromSettings() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// Adds a carb entry with the specified value
    func addCarbEntry(value: String) {
        navigateToTrackTab()
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        carbTextField.tap()
        carbTextField.typeText(value)
        addButton.tap()
    }

    /// Verifies that a specific carb value is displayed
    func verifyCarbValueExists(_ value: String) {
        XCTAssertTrue(app.staticTexts[value].exists, "Carb value '\(value)' should be displayed")
    }

    /// Verifies that the carb limit warning is displayed
    func verifyCarbLimitWarningDisplayed() {
        XCTAssertTrue(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)
    }

    /// Verifies that the carb limit warning is not displayed
    func verifyCarbLimitWarningHidden() {
        XCTAssertFalse(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)
    }
}
