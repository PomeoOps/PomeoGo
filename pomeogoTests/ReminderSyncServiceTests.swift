import XCTest
@testable import pomeogo

final class ReminderSyncServiceTests: XCTestCase {
    func testRequestAccess() {
        let exp = expectation(description: "权限申请")
        ReminderSyncService.shared.requestAccess { granted, error in
            // 只要能回调就算通过
            XCTAssertNil(error)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
    }

    func testFetchReminders() {
        let exp = expectation(description: "读取提醒事项")
        ReminderSyncService.shared.fetchReminders { reminders, error in
            // 只要能回调就算通过
            XCTAssertNil(error)
            XCTAssertNotNil(reminders)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10.0)
    }
} 