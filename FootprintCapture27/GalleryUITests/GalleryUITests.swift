import XCTest

final class GalleryUITests: XCTestCase {
    // CI installs a single deer capture in the simulator's Documents folder.
    func testFilterRecoveryAndDetail() {
        let app = XCUIApplication()
        app.launch()
        let card = app.buttons["gallery.record"].firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        app.buttons["gallery.options"].tap()
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
