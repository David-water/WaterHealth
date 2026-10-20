import XCTest
@testable import WaterHealth

final class WaterHealthTests: XCTestCase {
    func testCSVIsAtomicAndRejectsWrongUnits() throws {
        let invalid = "metric,value,unit,date\nheartRate,68,次/分,2020-01-01\nsystolic,120,kPa,2020-01-01\n"
        XCTAssertThrowsError(try CSVImporter.parse(Data(invalid.utf8)))
        let valid = "metric,value,unit,date\nheartRate,68,次/分,2020-01-01\n"
        let result = try CSVImporter.parse(Data(valid.utf8))
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.reading.value, 68)
    }
    func testCSVRejectsNonfiniteAndFuture() {
        for value in ["nan", "inf", "-1"] {
            XCTAssertThrowsError(try CSVImporter.parse(Data("metric,value,unit,date\nheartRate,\(value),次/分,2020-01-01".utf8)))
        }
        XCTAssertThrowsError(try CSVImporter.parse(Data("metric,value,unit,date\nheartRate,68,次/分,2099-01-01".utf8)))
    }
    @MainActor func testPersistenceGoalsAndCart() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = HealthStore(directory: directory)
        store.finishOnboarding(profile: Profile(), demo: true)
        let goal = try XCTUnwrap(store.state.goals.first)
        store.logGoal(goal.id, amount: 999)
        XCTAssertEqual(store.state.goals.first?.current, goal.target)
        store.logGoal(goal.id, amount: -999)
        XCTAssertEqual(store.state.goals.first?.current, 0)
        store.changeCart("omega", delta: 2)
        XCTAssertEqual(store.cartTotal, 31800)
        XCTAssertTrue(store.checkout())
        XCTAssertEqual(store.cartCount, 0)
        let reopened = HealthStore(directory: directory)
        XCTAssertEqual(reopened.state.orders.count, 1)
        XCTAssertEqual(reopened.state.orders.first?.totalCents, 31800)
        XCTAssertEqual(reopened.state.goals.first?.logs.count, 2)
    }
    @MainActor func testDuplicateReadingsAreNotAccumulated() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = HealthStore(directory: directory)
        let record = ImportedReading(metricID: "heartRate", reading: Reading(date: Date(timeIntervalSince1970: 100), value: 68, source: "test"))
        XCTAssertTrue(store.mergeReadings([record, record]))
        XCTAssertEqual(store.metric("heartRate")?.readings.count, 1)
    }
    func testAssistantDoesNotSuggestMedicationDose() {
        let reply = HealthAssistant.reply(to: "我的药物剂量是多少", state: DemoData.state())
        XCTAssertTrue(reply.contains("不能"))
        XCTAssertTrue(reply.contains("医生"))
    }
    @MainActor func testUnreadableArchiveIsNeverSilentlyOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = Data("unreadable archive".utf8)
        let file = directory.appendingPathComponent("health-records.json")
        try original.write(to: file)
        let store = HealthStore(directory: directory)
        store.updateProfile(Profile())
        XCTAssertEqual(try Data(contentsOf: file), original)
        XCTAssertEqual(try store.exportData(), original)
        store.reset(demo: true)
        XCTAssertTrue(store.state.isDemo)
        let backup = try XCTUnwrap(FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil).first { $0.lastPathComponent.hasPrefix("recovery-") })
        XCTAssertEqual(try Data(contentsOf: backup), original)
    }
}
