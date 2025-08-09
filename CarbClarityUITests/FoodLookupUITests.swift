//
//  FoodLookupUITests.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 13.07.25.
//

import XCTest

final class FoodLookupUITests: CarbClarityUITestBase {

    override var additionalLaunchArguments: [String] {
        return ["--enable-food-lookup", "--test-api-key"]
    }

    // MARK: - Food Lookup Access Tests

    func testFoodLookupButtonAppears() throws {
        enableFoodLookup()

        XCTAssertTrue(app.buttons["Food Lookup"].exists)
    }

    func testOpenFoodLookup() throws {
        enableFoodLookup()

        app.buttons["Food Lookup"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.exists || app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS 'Search'")).firstMatch.exists)

        XCTAssertTrue(app.navigationBars.buttons["Done"].exists)

        app.tapNavigationDone()

        XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
    }

    // MARK: - Search Functionality Tests

    func testSearchForFood() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("apple")

        let appleResult = app.staticTexts["Apples, raw, with skin"]
        XCTAssertTrue(appleResult.waitForExistence(timeout: 3), "Apple search result should appear")
        
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'apple'")).count > 1, "Multiple apple results should appear")
        
        XCTAssertTrue(searchField.value as? String == "apple" || (searchField.value as? String)?.contains("apple") == true)
    }

    func testEmptySearchHandling() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch

        searchField.tap()
        searchField.typeText("")

        XCTAssertTrue(searchField.exists)
    }

    // MARK: - Food Selection Tests

    func testFoodSelection() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("banana")

        let bananaResult = app.staticTexts["Bananas, raw"]
        XCTAssertTrue(bananaResult.waitForExistence(timeout: 3), "Banana result should appear")
        
        bananaResult.tap()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '22.8g'")).firstMatch.waitForExistence(timeout: 2), "Carb content should be displayed")
    }

    func testAmountEntry() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("rice")
        
        let riceResult = app.staticTexts["Rice, white, long-grain, regular, cooked"]
        XCTAssertTrue(riceResult.waitForExistence(timeout: 3), "Rice result should appear")
        riceResult.tap()

        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Amount'")).firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 2), "Amount entry field should exist")
        
        amountField.tap()
        amountField.typeText("200")

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '56.4g'")).firstMatch.waitForExistence(timeout: 2), "Calculated carbs should appear")
    }
    
    func testLoadingCarbsForFood() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("pizza")
        
        let pizzaResult = app.staticTexts["Pizza, cheese topping, regular crust"]
        XCTAssertTrue(pizzaResult.waitForExistence(timeout: 3), "Pizza result should appear")
        
        XCTAssertTrue(app.staticTexts["Loading..."].exists, "Loading text should appear initially")
        
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '32.4g'")).firstMatch.waitForExistence(timeout: 3), "Loaded carb value should appear")
    }
    
    func testCompleteAddCarbFlow() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        searchField.tap()
        searchField.typeText("bread")
        
        let breadResult = app.staticTexts["Bread, white, commercially prepared"]
        XCTAssertTrue(breadResult.waitForExistence(timeout: 3), "Bread result should appear")
        breadResult.tap()

        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == 'Amount'")).firstMatch
        XCTAssertTrue(amountField.waitForExistence(timeout: 2), "Amount entry field should exist")
        amountField.tap()
        amountField.typeText("50")

        let addButton = app.buttons["Add to Daily Total"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 2), "Add button should exist")
        XCTAssertTrue(addButton.isEnabled, "Add button should be enabled")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["Today's total carb intake"].waitForExistence(timeout: 3), "Should return to main screen")
        
        XCTAssertTrue(app.staticTexts["24.7g"].waitForExistence(timeout: 2), "Added carbs should appear in total")
    }

    // MARK: - Error Handling Tests

    func testInvalidAPIKeyHandling() throws {
        app.buttons["Settings"].tap()

        app.swipeUp(velocity: .slow)

        let apiKeyField = app.textFields["API Key"]
        if apiKeyField.exists {
            apiKeyField.tap()
            apiKeyField.clearText()
        }

        app.tapNavigationDone()

        if app.buttons["Food Lookup"].exists {
            app.buttons["Food Lookup"].tap()

            XCTAssertTrue(app.exists)
        }
    }

    // MARK: - Accessibility Tests

    func testFoodLookupAccessibility() throws {
        enableFoodLookup()
        app.buttons["Food Lookup"].tap()

        let searchField = app.searchFields.firstMatch.exists ? app.searchFields.firstMatch : app.textFields.firstMatch
        XCTAssertTrue(searchField.isHittable)

        XCTAssertTrue(app.buttons["Done"].isHittable)

        XCTAssertTrue(searchField.exists)
    }

    // MARK: - Performance Tests

    func testLookupInterfaceResponsiveness() throws {
        enableFoodLookup()

        measure {
            app.buttons["Food Lookup"].tap()
            app.tapNavigationDone()
        }
    }

    // MARK: - Helper Methods

    private func enableFoodLookup() {
        app.buttons["Settings"].tap()
        app.swipeUp(velocity: .slow)

        let apiKeyField = app.textFields["API Key"]
        apiKeyField.tap()
        apiKeyField.clearText()
        apiKeyField.typeText("test-api-key-for-ui-testing")

        let lookupSwitch = app.switches["Enable USDA FoodData Lookup"]
        if !lookupSwitch.isOn {
            lookupSwitch.tap()
        }

        app.tapNavigationDone()
    }
}

