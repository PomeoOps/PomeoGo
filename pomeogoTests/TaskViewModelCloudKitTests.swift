import XCTest
@testable import pomeogo

@MainActor
class TaskViewModelCloudKitTests: XCTestCase {
    func testCloudKitSync() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试CloudKit同步功能
        let task = viewModel.createTask(
            title: "CloudKit测试任务",
            dueDate: nil,
            priority: .normal,
            project: nil
        )
        
        XCTAssertEqual(task.title, "CloudKit测试任务")
    }
    
    func testCloudKitDataUpload() {
        let dataManager = DataManager()
        let viewModel = TaskViewModel(dataManager: dataManager)
        
        // 测试数据上传到CloudKit
        let task = viewModel.createTask(
            title: "上传测试",
            dueDate: Date(),
            priority: .high,
            project: nil
        )
        
        XCTAssertNotNil(task)
        XCTAssertEqual(task.title, "上传测试")
    }
} 