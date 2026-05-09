import XCTest

final class AccurateClockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDigitalClockShowsHHMMSS() throws {
        let app = XCUIApplication()
        app.launch()

        let digital = app.descendants(matching: .any)["digital-clock"].firstMatch
        XCTAssertTrue(digital.waitForExistence(timeout: 5), "digital-clock element not found")

        let pattern = #"^\d{2}:\d{2}:\d{2}$"#
        let label = digital.label
        XCTAssertTrue(
            NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: label),
            "Digital clock label \(label.debugDescription) does not match HH:MM:SS"
        )
    }

    @MainActor
    func testTimezonePickerSwapsTime() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-timezoneIdentifier", ""]
        app.launch()

        let timezoneButton = app.buttons["timezone-button"]
        XCTAssertTrue(timezoneButton.waitForExistence(timeout: 5), "timezone button missing")
        timezoneButton.tap()

        XCTAssertTrue(app.navigationBars["Time Zone"].waitForExistence(timeout: 3))

        let pickerScreenshot = XCTAttachment(screenshot: app.screenshot())
        pickerScreenshot.name = "Time Zone Picker"
        pickerScreenshot.lifetime = .keepAlways
        add(pickerScreenshot)

        // Honolulu is in the second offset group (UTC-10), visible without scrolling.
        let honoluluRow = app.buttons["Pacific/Honolulu"]
        XCTAssertTrue(honoluluRow.waitForExistence(timeout: 3), "Honolulu row missing")
        honoluluRow.tap()

        XCTAssertTrue(
            app.staticTexts["Honolulu • UTC\u{2212}10"].waitForExistence(timeout: 3),
            "Non-local indicator did not appear after selecting Honolulu"
        )
    }
}
