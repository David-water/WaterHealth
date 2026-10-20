import XCTest

final class WaterHealthUITests: XCTestCase {
    func testIPadLandscapeLayoutAndCapture() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = XCUIApplication()
        app.launchArguments = ["--screenshots", "--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["openAssistant"].waitForExistence(timeout: 10))
        for (name, tab) in [("20-ipad-landscape-twin", "数字孪生"), ("21-ipad-landscape-reports", "健康报告"), ("22-ipad-landscape-goals", "健康目标")] {
            app.buttons[tab].tap()
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    func testCoreNavigationAndLocalChat() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["openAssistant"].waitForExistence(timeout: 10))
        for tab in ["健康报告", "健康目标", "营养药房", "我的档案", "数字孪生"] {
            app.buttons["tab_\(tab)"].tap()
        }
        app.buttons["openAssistant"].tap()
        let input = app.textFields["chatInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap(); input.typeText("目标")
        app.buttons["sendChat"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "你的计划中有")).firstMatch.waitForExistence(timeout: 5))
    }
    func testNewGoalIsUsable() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--demo"]
        app.launch()
        app.buttons["tab_健康目标"].tap()
        app.buttons["addGoal"].tap()
        let title = app.textFields["goalTitle"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("阅读记录")
        app.buttons["saveGoal"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["logGoal_阅读记录"].waitForExistence(timeout: 5))
        app.buttons["logGoal_阅读记录"].tap()
    }
}
