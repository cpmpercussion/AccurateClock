import XCTest

/// Captures the marketing screenshots used in the App Store listing.
///
/// Run on each device size required by App Store Connect; attachments are written
/// into the test result bundle and extracted by `tools/screenshots.sh`.
final class MarketingScreenshots: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-screenshotTime", "2026-05-09 10:08:42.500",
            "-screenshotMockSync",
            "-secondsStyle", "sweep",
            "-timezoneIdentifier", "",
        ]
        app.launch()

        // 1. Sweep face, system timezone, freshly synced.
        attach(name: "01_sweep", screenshot: app.screenshot())

        // 2. Tick face — flip the segmented control.
        let tickButton = app.buttons["Tick"]
        XCTAssertTrue(tickButton.waitForExistence(timeout: 3))
        tickButton.tap()
        attach(name: "02_tick", screenshot: app.screenshot())

        // 3. Timezone picker open.
        app.buttons["Sweep"].tap()
        let timezoneButton = app.buttons["timezone-button"]
        XCTAssertTrue(timezoneButton.waitForExistence(timeout: 3))
        timezoneButton.tap()
        XCTAssertTrue(app.navigationBars["Time Zone"].waitForExistence(timeout: 3))
        attach(name: "03_picker", screenshot: app.screenshot())

        // 4. Selected non-local zone — Tokyo (UTC+9). The picker is a long sectioned
        // list; scroll until Tokyo's row is hittable, then tap.
        let tokyoRow = app.buttons["Asia/Tokyo"]
        var swipes = 0
        while !tokyoRow.isHittable && swipes < 12 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(tokyoRow.waitForExistence(timeout: 3), "Tokyo row not found after \(swipes) swipes")
        tokyoRow.tap()
        XCTAssertTrue(
            app.staticTexts["Tokyo • UTC+9"].waitForExistence(timeout: 3),
            "Tokyo non-local indicator did not appear"
        )
        attach(name: "04_tokyo", screenshot: app.screenshot())
    }

    private func attach(name: String, screenshot: XCUIScreenshot) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
