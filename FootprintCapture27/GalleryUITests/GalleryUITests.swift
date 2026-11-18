import XCTest

final class GalleryUITests: XCTestCase {
    // CI installs a single deer capture in the simulator's Documents folder.
    func testFilterRecoveryAndDetail() {
        let app = XCUIApplication()
        continueAfterFailure = false
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        addTeardownBlock {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "gallery-test-screen"
            attachment.lifetime = .keepAlways
            self.add(attachment)
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowLocation = springboard.buttons["Allow While Using App"]
        if allowLocation.waitForExistence(timeout: 3) { allowLocation.tap() }
        let card = app.buttons["gallery.record"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        let options = app.buttons["gallery.options"]
        XCTAssertTrue(options.exists)
        options.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["動物の種類"].firstMatch.tap()
        app.buttons["イノシシ"].firstMatch.tap()

        let reset = app.buttons["絞り込みを解除"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        XCTAssertFalse(card.exists)
        reset.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        card.tap()
        XCTAssertTrue(app.navigationBars["キャプチャ詳細"].waitForExistence(timeout: 5))
        app.buttons["閉じる"].firstMatch.tap()
        XCTAssertTrue(card.waitForExistence(timeout: 5))
    }
}
