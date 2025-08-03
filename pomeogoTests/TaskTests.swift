import XCTest
@testable import pomeogo

final class TaskTests: XCTestCase {
    func testTaskInit() {
        let task = SubXTask(title: "测试任务")
        XCTAssertEqual(task.title, "测试任务")
        XCTAssertFalse(task.isCompleted)
    }
} 