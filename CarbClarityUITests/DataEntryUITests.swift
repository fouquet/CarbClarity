//
//  DataEntryUITests.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 13.07.25.
//

import XCTest

final class DataEntryUITests: CarbClarityUITestBase {

    // MARK: - Basic Data Entry Tests

    func testSingleCarbEntry() throws {
        // Given
        
        // When
        addCarbEntry(value: "12.5")

        // Then
        verifyCarbValueExists("12.5g")

        let carbTextField = app.textFields["New carbs in grams"]
        let fieldValue = carbTextField.value as? String
        XCTAssertEqual(fieldValue, "New carbs in grams")
    }

    func testMultipleCarbEntries() throws {
        // Given
        let entries = ["10", "5.5", "8.25", "15"]

        // When
        for entry in entries {
            addCarbEntry(value: entry)

            verifyCarbValueExists("\(entry)g")
        }

        // Then
        verifyCarbValueExists("38.75g")
    }

    func testZeroCarbEntry() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        carbTextField.tap()
        carbTextField.typeText("0")

        if addButton.isEnabled {
            addButton.tap()
        }

        XCTAssertTrue(app.staticTexts["0g"].exists || app.staticTexts["0.0g"].exists)
    }

    func testNegativeCarbEntry() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        carbTextField.tap()
        carbTextField.typeText("-5")

        if addButton.isEnabled {
            addButton.tap()
        }

        XCTAssertFalse(app.staticTexts["-5g"].exists)
        XCTAssertTrue(app.staticTexts["0g"].exists || app.staticTexts["0.0g"].exists)
    }

    func testVeryLargeCarbEntry() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("999.99")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["999.99g"].exists)
    }

    func testDecimalCarbEntry() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        let decimalValues = ["1.5", "10.25", "0.75", "22.12"]

        for value in decimalValues {
            carbTextField.tap()
            carbTextField.clearText()
            carbTextField.typeText(value)
            addButton.tap()

            XCTAssertTrue(app.staticTexts["\(value)g"].exists)
        }
    }

    // MARK: - Data Display Tests

    func testCarbEntryListDisplay() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        let entries = ["5", "10", "15"]

        for entry in entries {
            carbTextField.tap()
            carbTextField.typeText(entry)
            addButton.tap()
            sleep(1)
        }

        for entry in entries {
            XCTAssertTrue(app.staticTexts["\(entry)g"].exists)
        }
        let timeElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS ':' OR label CONTAINS 'AM' OR label CONTAINS 'PM'"))
        XCTAssertGreaterThan(timeElements.count, 0)
    }

    func testDayGrouping() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        carbTextField.tap()
        carbTextField.typeText("8")
        addButton.tap()

        carbTextField.tap()
        carbTextField.typeText("12")
        addButton.tap()
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let datePattern = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '\(Calendar.current.component(.day, from: today))'"))
        XCTAssertGreaterThan(datePattern.count, 0)
    }

    func testTotalCalculation() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        let entries = ["2.25", "3.75", "4.5", "10"]
        var expectedTotal: Double = 0

        for entry in entries {
            carbTextField.tap()
            carbTextField.typeText(entry)
            addButton.tap()

            expectedTotal += Double(entry) ?? 0
        }

        XCTAssertTrue(app.staticTexts["20.5g"].exists)
    }

    // MARK: - Entry Deletion Tests

    func testEditModeToggle() throws {
        // Given
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("15")

        if app.keyboards.firstMatch.exists {
            app.tapKeyboardDone()
        }

        addButton.tap()

        XCTAssertTrue(app.staticTexts["15g"].exists)

        // When
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.exists)
        XCTAssertEqual(editButton.label, "Edit")

        editButton.tap()

        // Then
        XCTAssertEqual(editButton.label, "Done")

        // When
        editButton.tap()

        // Then
        XCTAssertEqual(editButton.label, "Edit")

        XCTAssertTrue(app.staticTexts["15g"].exists)
    }

    func testEditModeAccessibility() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        let entries = ["10", "15", "20"]
        for entry in entries {
            carbTextField.tap()
            carbTextField.typeText(entry)
            addButton.tap()
        }

        if app.keyboards.firstMatch.exists {
            app.tapKeyboardDone()
        }
        for entry in entries {
            XCTAssertTrue(app.staticTexts["\(entry)g"].exists)
        }

        app.buttons["Edit"].tap()
        for entry in entries {
            XCTAssertTrue(app.staticTexts["\(entry)g"].exists)
            XCTAssertTrue(app.staticTexts["\(entry)g"].isHittable)
        }

        app.buttons["Edit"].tap()
        for entry in entries {
            XCTAssertTrue(app.staticTexts["\(entry)g"].exists)
        }
    }

    // MARK: - Limit Warning Tests

    func testCarbLimitWarning() throws {
        app.buttons["Settings"].tap()

        let cautionSwitch = app.switches["Caution limit enabled"]
        if cautionSwitch.isOn {
            cautionSwitch.tap()
        }

        let warningSwitch = app.switches["Warning limit enabled"]
        if !warningSwitch.isOn {
            warningSwitch.tap()
        }

        let limitTextField = app.textFields["Warning Limit"]
        limitTextField.tap()
        limitTextField.clearText()
        limitTextField.typeText("20")

        app.tapNavigationDone()

        let carbTextField = app.textFields["New carbs in grams"]
        carbTextField.tap()
        carbTextField.typeText("25")
        app.buttons["Add"].tap()

        XCTAssertTrue(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)
    }

    func testCarbLimitWarningMultipleEntries() throws {
        app.buttons["Settings"].tap()

        let cautionSwitch = app.switches["Caution limit enabled"]
        if cautionSwitch.isOn {
            cautionSwitch.tap()
        }

        let warningSwitch = app.switches["Warning limit enabled"]
        if !warningSwitch.isOn {
            warningSwitch.tap()
        }

        let limitTextField = app.textFields["Warning Limit"]
        limitTextField.tap()
        limitTextField.clearText()
        limitTextField.typeText("30")
        app.tapNavigationDone()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]

        carbTextField.tap()
        carbTextField.typeText("15")
        addButton.tap()

        XCTAssertFalse(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)

        carbTextField.tap()
        carbTextField.typeText("10")
        addButton.tap()

        XCTAssertFalse(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)

        carbTextField.tap()
        carbTextField.typeText("10")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["⚠️ You are exceeding your carb limit ⚠️"].exists)
    }

    // MARK: - Input Validation Tests

    func testEmptyInputHandling() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("")

        if addButton.isEnabled {
            addButton.tap()
        }

        XCTAssertTrue(app.staticTexts["0g"].exists || app.staticTexts["0.0g"].exists)
    }

    func testInvalidCharacterInputHandling() throws {
        let carbTextField = app.textFields["New carbs in grams"]

        carbTextField.tap()
        carbTextField.typeText("abc")

        XCTAssertTrue(carbTextField.exists)
    }

    func testVeryLongDecimalInputHandling() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("12.123456789")
        addButton.tap()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '12.12'")).firstMatch.exists)
    }

    // MARK: - Keyboard Interaction Tests

    func testKeyboardAppearanceAndDismissal() throws {
        let carbTextField = app.textFields["New carbs in grams"]

        carbTextField.tap()

        XCTAssertTrue(app.keyboards.firstMatch.exists)

        if app.keyboards.firstMatch.exists {
            app.tapKeyboardDone()

            XCTAssertFalse(app.keyboards.firstMatch.exists)
        }
    }

    func testNumericKeyboardType() throws {
        let carbTextField = app.textFields["New carbs in grams"]

        carbTextField.tap()

        XCTAssertTrue(app.keyboards.firstMatch.exists)
        XCTAssertTrue(app.keys["0"].exists)
        XCTAssertTrue(app.keys["1"].exists)
        XCTAssertTrue(app.keys["5"].exists)
        XCTAssertTrue(app.keys["9"].exists)
    }

    // MARK: - Performance Tests

    func testManyEntriesPerformance() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        for i in 1...11 {
            carbTextField.tap()
            carbTextField.clearText()
            carbTextField.typeText("\(i)")
            addButton.tap()
        }

        XCTAssertTrue(app.staticTexts["66g"].exists)
    }

    func testScrollingPerformanceWithManyEntries() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        for i in 1...15 {
            carbTextField.tap()
            carbTextField.clearText()
            carbTextField.typeText("\(i)")
            addButton.tap()
        }

        measure {
            let entryList = app.tables.firstMatch.exists ? app.tables.firstMatch : app.collectionViews.firstMatch

            if entryList.exists {
                for _ in 1...5 {
                    entryList.swipeUp()
                    entryList.swipeDown()
                }
            }
        }
    }

    // MARK: - Edge Cases

    func testRapidEntryAddition() throws {
        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        for i in 1...10 {
            carbTextField.tap()
            carbTextField.typeText("\(i)")
            addButton.tap()
            usleep(100000)
        }

        XCTAssertTrue(app.staticTexts["55g"].exists)
    }

    func testInterruptedEntry() throws {
        let carbTextField = app.textFields["New carbs in grams"]

        carbTextField.tap()
        carbTextField.typeText("12.5")

        app.buttons["Settings"].tap()
        app.tapNavigationDone()

        XCTAssertEqual(carbTextField.value as? String, "12.5")

        app.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["12.5g"].exists)
    }

    // MARK: - Entry Sorting Tests

    func testEntrySortingByTime() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("5")
        addButton.tap()

        sleep(1)
        carbTextField.tap()
        carbTextField.typeText("10")
        addButton.tap()

        sleep(1)
        carbTextField.tap()
        carbTextField.typeText("15")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["5g"].exists)
        XCTAssertTrue(app.staticTexts["10g"].exists)
        XCTAssertTrue(app.staticTexts["15g"].exists)

        XCTAssertTrue(app.staticTexts["5g"].isHittable)
        XCTAssertTrue(app.staticTexts["10g"].isHittable)
        XCTAssertTrue(app.staticTexts["15g"].isHittable)
    }

    func testMultipleDayEntrySorting() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("8")
        addButton.tap()

        carbTextField.tap()
        carbTextField.typeText("12")
        addButton.tap()
        XCTAssertTrue(app.staticTexts["8g"].exists)
        XCTAssertTrue(app.staticTexts["12g"].exists)

        XCTAssertTrue(app.staticTexts["20g"].exists)
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        let todayString = formatter.string(from: today)

        let dayComponent = Calendar.current.component(.day, from: today)
        let dayPattern = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '\(dayComponent)'"))
        XCTAssertGreaterThan(dayPattern.count, 0)
    }

    func testEntrySortingWithIdenticalValues() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("7")
        addButton.tap()

        sleep(1)

        carbTextField.tap()
        carbTextField.typeText("7")
        addButton.tap()
        let sevenGramEntries = app.staticTexts.matching(identifier: "7g")
        XCTAssertGreaterThanOrEqual(sevenGramEntries.count, 2)

        XCTAssertTrue(app.staticTexts["14g"].exists)
    }

    // MARK: - Carb Value Rounding Tests

    func testCarbValueRoundingDisplay() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("12.555")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["12.56g"].exists)
        XCTAssertFalse(app.staticTexts["12.555g"].exists)

        XCTAssertTrue(app.staticTexts["12.56g"].exists)
    }

    func testCarbValueRoundingMultipleEntries() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("5.444")
        addButton.tap()

        carbTextField.tap()
        carbTextField.typeText("7.556")
        addButton.tap()
        XCTAssertTrue(app.staticTexts["5.44g"].exists)
        XCTAssertTrue(app.staticTexts["7.56g"].exists)

        XCTAssertTrue(app.staticTexts["13g"].exists)
    }

    func testCarbValueRoundingWholeNumbers() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("5")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["5g"].exists)
        XCTAssertFalse(app.staticTexts["5.0g"].exists)
        XCTAssertFalse(app.staticTexts["5.00g"].exists)
    }

    func testCarbValueRoundingTwoDecimalPlaces() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("12.34")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["12.34g"].exists)
    }

    func testCarbValueRoundingVerySmallValues() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("0.005")
        addButton.tap()

        XCTAssertTrue(app.staticTexts["0.01g"].exists)
        XCTAssertFalse(app.staticTexts["0.005g"].exists)
    }

    func testCarbValueRoundingInTotal() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("3.333")
        addButton.tap()

        carbTextField.tap()
        carbTextField.typeText("4.447")
        addButton.tap()
        XCTAssertTrue(app.staticTexts["3.33g"].exists)
        XCTAssertTrue(app.staticTexts["4.45g"].exists)

        XCTAssertTrue(app.staticTexts["7.78g"].exists)
    }

    func testCarbValueRoundingInDayTotal() throws {
        navigateToTrackTab()

        let carbTextField = app.textFields["New carbs in grams"]
        let addButton = app.buttons["Add"]
        carbTextField.tap()
        carbTextField.typeText("4.445")
        addButton.tap()

        carbTextField.tap()
        carbTextField.typeText("5.556")
        addButton.tap()
        XCTAssertTrue(app.staticTexts["4.45g"].exists)
        XCTAssertTrue(app.staticTexts["5.56g"].exists)

        let dayTotal = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Total: 10.01g'"))
        XCTAssertEqual(dayTotal.count, 1)
    }
}

