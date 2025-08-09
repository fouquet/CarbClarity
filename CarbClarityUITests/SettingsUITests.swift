//
//  SettingsUITests.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 13.07.25.
//

import XCTest

final class SettingsUITests: CarbClarityUITestBase {

    func testOpenSettingsFromMainScreen() throws {
        navigateToSettings()

        XCTAssertTrue(app.navigationBars.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Warning Limit".uppercased()].exists)
        XCTAssertTrue(app.staticTexts["Caution Limit".uppercased()].exists)
        XCTAssertTrue(app.staticTexts["Food Lookup".uppercased()].exists)

        app.swipeUp()

        XCTAssertTrue(app.staticTexts["About".uppercased()].exists)
    }

    func testCloseSettings() throws {
        navigateToSettings()

        app.tapNavigationDone()

        verifyMainScreenLoaded()
    }

    // MARK: - Warning Limit Section Tests

    func testWarningLimitSection() throws {
        navigateToSettings()

        XCTAssertTrue(app.staticTexts["Warning Limit".uppercased()].exists)
        XCTAssertTrue(app.staticTexts["Warning limit enabled"].exists)
        XCTAssertTrue(app.staticTexts["Warning limit in grams"].exists)
        XCTAssertTrue(app.switches["Warning limit enabled"].exists)
        XCTAssertTrue(app.textFields["Warning Limit"].exists)
    }

    func testCautionLimitSection() throws {
        navigateToSettings()

        XCTAssertTrue(app.staticTexts["Caution Limit".uppercased()].exists)
        XCTAssertTrue(app.staticTexts["Caution limit enabled"].exists)
        XCTAssertTrue(app.staticTexts["Caution limit in grams"].exists)
        XCTAssertTrue(app.switches["Caution limit enabled"].exists)
        XCTAssertTrue(app.textFields["Caution Limit"].exists)
    }

    func testChangeWarningLimit() throws {
        navigateToSettings()

        let limitTextField = app.textFields["Warning Limit"]

        limitTextField.tap()
        limitTextField.clearText()
        limitTextField.typeText("25")

        XCTAssertEqual(limitTextField.value as? String, "25")

        app.tapNavigationDone()

        app.buttons["Settings"].tap()
        XCTAssertEqual(app.textFields["Warning Limit"].value as? String, "25")
    }

    func testChangeCautionLimit() throws {
        navigateToSettings()

        let cautionSwitch = app.switches["Caution limit enabled"]
        if !cautionSwitch.isOn {
            cautionSwitch.tap()
        }

        let limitTextField = app.textFields["Caution Limit"]

        XCTAssertTrue(limitTextField.isEnabled, "Caution Limit text field should be enabled when switch is on")

        limitTextField.tap()
        limitTextField.clearText()
        limitTextField.typeText("18")

        XCTAssertEqual(limitTextField.value as? String, "18")

        app.tapNavigationDone()

        app.buttons["Settings"].tap()
        XCTAssertEqual(app.textFields["Caution Limit"].value as? String, "18")
    }

    func testLimitDecimalValues() throws {
        app.buttons["Settings"].tap()

        let warningSwitch = app.switches["Warning limit enabled"]
        if !warningSwitch.isOn {
            warningSwitch.tap()
        }

        let cautionSwitch = app.switches["Caution limit enabled"]
        if !cautionSwitch.isOn {
            cautionSwitch.tap()
        }

        let warningLimitTextField = app.textFields["Warning Limit"]
        let cautionLimitTextField = app.textFields["Caution Limit"]

        warningLimitTextField.tap()
        warningLimitTextField.clearText()
        warningLimitTextField.typeText("22.5")

        XCTAssertEqual(warningLimitTextField.value as? String, "22.5")

        cautionLimitTextField.tap()
        cautionLimitTextField.clearText()
        cautionLimitTextField.typeText("17.5")

        XCTAssertEqual(cautionLimitTextField.value as? String, "17.5")
    }

    // MARK: - Food Lookup Section Tests

    func testFoodLookupSection() throws {
        app.buttons["Settings"].tap()

        app.swipeUp(velocity: .slow)

        XCTAssertTrue(app.staticTexts["Food Lookup".uppercased()].exists)
        XCTAssertTrue(app.switches["Enable USDA FoodData Lookup"].exists)
        XCTAssertTrue(app.textFields["API Key"].exists)
    }

    func testFoodLookupToggle() throws {
        app.buttons["Settings"].tap()

        app.swipeUp(velocity: .slow)

        let lookupSwitch = app.switches["Enable USDA FoodData Lookup"]
        let initialState = lookupSwitch.isOn

        lookupSwitch.tap()

        if app.alerts["API Key Required"].exists {
            XCTAssertTrue(app.staticTexts["This functionality requires an API key. Please enter an API key."].exists)

            XCTAssertTrue(app.buttons["OK"].exists)
            XCTAssertTrue(app.buttons["Get API Key"].exists)

            app.buttons["OK"].tap()

            XCTAssertEqual(lookupSwitch.isOn, initialState)
        }
    }

    func testAPIKeyEntry() throws {
        app.buttons["Settings"].tap()
        app.swipeUp(velocity: .slow)

        let apiKeyField = app.textFields["API Key"]
        apiKeyField.tap()
        apiKeyField.clearText()
        apiKeyField.typeText("test-api-key-12345")

        XCTAssertEqual(apiKeyField.value as? String, "test-api-key-12345")

        let lookupSwitch = app.switches["Enable USDA FoodData Lookup"]

        if !lookupSwitch.isOn {
            lookupSwitch.tap()

            XCTAssertFalse(app.alerts["API Key Required"].exists)
            XCTAssertTrue(lookupSwitch.isOn)
        }
    }

    // MARK: - Navigation Tests

    func testPrivacyPolicyNavigation() throws {
        app.buttons["Settings"].tap()

        app.swipeUp()

        app.buttons["Privacy Policy"].tap()

        XCTAssertTrue(app.navigationBars.staticTexts["Privacy Policy"].exists)
    }

    func testFAQNavigation() throws {
        app.buttons["Settings"].tap()

        app.swipeUp()

        app.buttons["FAQ"].tap()

        XCTAssertTrue(app.navigationBars.staticTexts["FAQ"].exists)
    }

    // MARK: - Accessibility Tests

    func testSettingsAccessibility() throws {
        app.buttons["Settings"].tap()

        XCTAssertTrue(app.buttons["Done"].isHittable)
        XCTAssertTrue(app.textFields["Warning Limit"].isHittable)
        XCTAssertTrue(app.textFields["Caution Limit"].isHittable)
        XCTAssertTrue(app.switches["Warning limit enabled"].isHittable)
        XCTAssertTrue(app.switches["Caution limit enabled"].isHittable)

        XCTAssertTrue(app.staticTexts["Warning Limit".uppercased()].exists)
        XCTAssertTrue(app.staticTexts["Caution Limit".uppercased()].exists)

        app.swipeUp(velocity: .slow)

        XCTAssertTrue(app.switches["Enable USDA FoodData Lookup"].isHittable)
        XCTAssertTrue(app.textFields["API Key"].isHittable)

        XCTAssertTrue(app.staticTexts["Food Lookup".uppercased()].exists)

        app.swipeUp(velocity: .slow)

        XCTAssertTrue(app.staticTexts["About".uppercased()].exists)
    }
}
