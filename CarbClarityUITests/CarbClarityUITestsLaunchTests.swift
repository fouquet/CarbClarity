//
//  CarbClarityUITestsLaunchTests.swift
//  CarbClarityUITests
//
//  Created by René Fouquet on 07.06.24.
//

import XCTest

@MainActor
final class CarbClarityUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = MainActor.assumeIsolated {
            let app = XCUIApplication()
            app.launch()

            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
            XCTAssertTrue(app.textFields["New carbs in grams"].exists)
            XCTAssertTrue(app.buttons["Add"].exists)
            XCTAssertTrue(app.buttons["Settings"].exists)

            return app
        }

        let attachment = XCTAttachment(screenshot: MainActor.assumeIsolated { app.screenshot() })
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testColdLaunch() throws {
        MainActor.assumeIsolated {
            let app = XCUIApplication()
            app.terminate()

            sleep(1)

            app.launch()

            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)

            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Cold Launch Screen"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    func testLaunchWithDifferentDeviceOrientations() throws {
        MainActor.assumeIsolated {
            let app = XCUIApplication()

            XCUIDevice.shared.orientation = .portrait
            app.launch()
            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)
            app.terminate()

            XCUIDevice.shared.orientation = .landscapeLeft
            app.launch()
            XCTAssertTrue(app.staticTexts["Today's total carb intake"].exists)

            XCUIDevice.shared.orientation = .portrait
        }
    }
}

