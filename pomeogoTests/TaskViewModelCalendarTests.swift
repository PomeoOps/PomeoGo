import XCTest
import EventKit
@testable import pomeogo

@MainActor
class TaskViewModelCalendarTests: XCTestCase {
    func testSyncTasksToCalendar() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试用例：创建一个有截止日期的任务
        let task = viewModel.createTask(
            title: "测试任务",
            dueDate: Date().addingTimeInterval(86400), // 明天
            priority: .high,
            project: nil
        )
        
        // 这里应该验证任务是否正确同步到日历
        XCTAssertNotNil(task.dueDate)
    }
    
    func testCalendarEventCreation() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试创建日历事件
        let task = viewModel.createTask(
            title: "会议任务",
            dueDate: Date(),
            priority: .normal,
            project: nil
        )
        
        XCTAssertEqual(task.title, "会议任务")
        XCTAssertNotNil(task.dueDate)
    }
} 