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
}
