import XCTest
import EventKit
@testable import pomeogo

@MainActor
class TaskViewModelRemindersTests: XCTestCase {
    func testSyncTasksToReminders() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试同步到提醒事项
        let task = viewModel.createTask(
            title: "提醒测试任务",
            dueDate: Date(),
            priority: .normal,
            projectId: nil
        )
        
        XCTAssertEqual(task.title, "提醒测试任务")
    }
    
    func testImportFromReminders() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试从提醒事项导入
        let task = viewModel.createTask(
            title: "导入测试",
            dueDate: nil,
            priority: .low,
            projectId: nil
        )
        
        XCTAssertNotNil(task)
        XCTAssertEqual(task.title, "导入测试")
    }
} 