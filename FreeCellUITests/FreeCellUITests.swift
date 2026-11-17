import XCTest

/// Plays a few moves on Microsoft deal #1, which is a Medium deal. Its bottom cards are
/// 6♠ 9♣ 2♥ 6♥ 6♣ 3♦ 8♣ 10♣, and there are no free columns.
final class FreeCellUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-deal", "1"]
        app.launch()
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
    }

    private func card(_ name: String) -> XCUIElement { app.images[name] }

    /// Turns the device, then waits until the window has the new shape and the turn animation is done.
    private func turn(to orientation: UIDeviceOrientation) {
        XCUIDevice.shared.orientation = orientation
        let window = app.windows.firstMatch
        let deadline = Date().addingTimeInterval(5)
        while (window.frame.width > window.frame.height) != orientation.isLandscape, Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertEqual(window.frame.width > window.frame.height, orientation.isLandscape)
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }

    func testTapSendsCardToFreeCell() {
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 5))
        // No column takes the 9 of clubs, so a tap puts it in a free cell.
        card("9 of clubs").tap()
        XCTAssertTrue(app.staticTexts["Moves: 1"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Undo"].isEnabled)
        app.buttons["Undo"].tap()
        XCTAssertTrue(app.staticTexts["Moves: 0"].waitForExistence(timeout: 2))
    }

    func testDragToFreeCellAndIllegalDragIsRefused() {
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 5))
        // Drag the 6 of spades straight up to the first free cell, which is above its column.
        let sixOfSpades = card("6 of spades")
        let start = sixOfSpades.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let freeCellMidY = app.buttons["New Game"].frame.maxY + sixOfSpades.frame.height / 2 + 16
        start.press(forDuration: 0.1, thenDragTo: start.withOffset(CGVector(dx: 0, dy: freeCellMidY - sixOfSpades.frame.midY)))
        XCTAssertTrue(app.staticTexts["Moves: 1"].waitForExistence(timeout: 2))

        // The 6 of hearts cannot go on the 10 of clubs.
        let sixOfHearts = card("6 of hearts").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let tenOfClubs = card("10 of clubs").coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        sixOfHearts.press(forDuration: 0.1, thenDragTo: tenOfClubs)
        XCTAssertTrue(app.staticTexts["That move is not allowed."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Moves: 1"].exists)
    }

    func testNewGameAsksBeforeAbandoningGame() {
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 5))
        card("9 of clubs").tap()
        XCTAssertTrue(app.staticTexts["Moves: 1"].waitForExistence(timeout: 2))

        app.buttons["New Game"].tap()
        let alert = app.alerts["Abandon this game?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        alert.buttons["Keep Playing"].tap()
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].exists)

        app.buttons["New Game"].tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        alert.buttons["New Game"].tap()
        XCTAssertTrue(app.staticTexts["Moves: 0"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Game #1 · Medium"].exists)
    }

    func testPlayInLandscapeThenTurnBack() {
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 5))
        turn(to: .landscapeLeft)

        card("9 of clubs").tap()
        XCTAssertTrue(app.staticTexts["Moves: 1"].waitForExistence(timeout: 2))
        XCTAssertTrue(card("9 of clubs").isHittable)

        turn(to: .portrait)
        app.buttons["Undo"].tap()
        XCTAssertTrue(app.staticTexts["Moves: 0"].waitForExistence(timeout: 2))
    }

    /// Opens the New Game menu with a long press and selects a difficulty.
    private func select(_ difficulty: String) {
        app.buttons["New Game"].press(forDuration: 1.0)
        let item = app.buttons[difficulty]
        XCTAssertTrue(item.waitForExistence(timeout: 2))
        item.tap()
    }

    func testDifficultyAppliesToTheNextNewGame() {
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 5))
        select("Hard")
        // The current game does not change.
        XCTAssertTrue(app.staticTexts["Game #1 · Medium"].waitForExistence(timeout: 2))

        app.buttons["New Game"].tap()
        let hardGame = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "· Hard")).firstMatch
        XCTAssertTrue(hardGame.waitForExistence(timeout: 2))
        XCTAssertFalse(app.staticTexts["Game #1 · Medium"].exists)

        // Put the default back for the next run.
        select("Easy")
    }
}
