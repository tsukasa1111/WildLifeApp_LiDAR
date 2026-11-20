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
        let card = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@", "gallery.record.", "-ci-fixture")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        app.buttons["撮影画面の見本"].tap()
        XCTAssertTrue(app.navigationBars["撮影画面の見本"].waitForExistence(timeout: 5))
        app.buttons["撮影中"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["preview.progress"].exists)
        attachScreen("preview")
        let sampleShot = app.buttons["写真を1枚撮影"]
        for _ in 0..<3 { sampleShot.tap() }
        XCTAssertTrue(app.staticTexts["50枚の撮影が完了しました"].exists)
        app.buttons["閉じる"].tap()
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
        attachScreen("detail")
        verifyFootprintMarkup(in: app)
        app.buttons["編集"].tap()
        XCTAssertTrue(app.navigationBars["記録の編集"].waitForExistence(timeout: 5))
        let withoutTrack = app.buttons["足跡なし"]
        let animal = app.descendants(matching: .any)["editor.animal"].firstMatch
        XCTAssertTrue(animal.exists)
        withoutTrack.tap()
        XCTAssertFalse(animal.exists)
        app.buttons["キャンセル"].tap()
        app.buttons["編集"].tap()
        XCTAssertTrue(animal.waitForExistence(timeout: 5))
        attachScreen("editor")
        withoutTrack.tap()
        app.buttons["保存"].tap()
        XCTAssertTrue(app.navigationBars["キャプチャ詳細"].waitForExistence(timeout: 5))
        app.buttons["閉じる"].firstMatch.tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(card.waitForExistence(timeout: 10))
        XCTAssertTrue(card.label.contains("足跡なし"))
    }
    func testRecordingFormSwitchesBetweenTrackAndSurveySite() {
        let app = XCUIApplication()
        app.launchArguments = ["-testMetadataForm"]
        app.launch()
        XCTAssertTrue(app.navigationBars["痕跡の記録"].waitForExistence(timeout: 8))
        app.buttons["足跡なし"].tap()
        XCTAssertTrue(app.navigationBars["調査地点の記録"].exists)
        attachScreen("record-form")
        app.buttons["足跡あり"].tap()
        XCTAssertTrue(app.navigationBars["痕跡の記録"].exists)
    }

    private func verifyFootprintMarkup(in app: XCUIApplication) {
        app.buttons["足跡画像を確認"].tap()
        app.buttons["画像を選択"].tap()
        app.buttons["写真 1"].tap()
        app.buttons["足跡を編集"].tap()
        let canvas = app.descendants(matching: .any)["annotation.canvas"].firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        app.buttons["大"].tap()
        for x in [0.25, 0.75] {
            canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.5)).tap()
        }
        XCTAssertTrue(app.staticTexts["2 / 10"].exists)
        app.buttons["すべての印を消す"].tap()
        app.alerts.buttons["キャンセル"].tap()
        XCTAssertTrue(app.staticTexts["2 / 10"].exists)
        attachScreen("markup")
        app.buttons["保存"].tap()
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.staticTexts["マーキング済み"].waitForExistence(timeout: 5))
        app.buttons["画像を選択"].tap()
        app.buttons["写真 2"].tap()
        XCTAssertTrue(app.staticTexts["元の写真"].waitForExistence(timeout: 5))
        app.buttons["画像を選択"].tap()
        app.buttons["写真 1"].tap()
        XCTAssertTrue(app.staticTexts["マーキング済み"].waitForExistence(timeout: 5))
        attachScreen("marked-photo")
        app.buttons["足跡を編集"].tap()
        XCTAssertTrue(app.staticTexts["2 / 10"].waitForExistence(timeout: 5))
        app.buttons["キャンセル"].tap()
        app.buttons["閉じる"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["キャプチャ詳細"].waitForExistence(timeout: 5))
    }

    private func attachScreen(_ name: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }
}
