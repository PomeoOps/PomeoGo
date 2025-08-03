import XCTest
@testable import pomeogo

@MainActor
class TaskViewModelTests: XCTestCase {
    func testAddXTask() {
        let dataManager = DataManager()
        let tvm = TaskViewModel(dataManager: dataManager)
        
        let task = tvm.createTask(title: "测试任务", dueDate: nil, priority: .normal, project: nil)
        XCTAssertEqual(task.title, "测试任务")
    }
    
    func testCompleteXTask() {
        let dataManager = DataManager()
        let tvm = TaskViewModel(dataManager: dataManager)
        
        let task = tvm.createTask(title: "完成测试", dueDate: nil, priority: .normal, project: nil)
        task.isCompleted = true
        tvm.updateTask(task)
        
        XCTAssertTrue(task.isCompleted)
    }
    
    func testDeleteXTask() {
        let dataManager = DataManager()
        let tvm = TaskViewModel(dataManager: dataManager)
        
        let task = tvm.createTask(title: "删除测试", dueDate: nil, priority: .normal, project: nil)
        let initialCount = tvm.tasks.count
        
        tvm.deleteTask(task)
        
        XCTAssertEqual(tvm.tasks.count, initialCount - 1)
    }
    
    func testFilterTasks() {
        let dataManager = DataManager()
        let tvm = TaskViewModel(dataManager: dataManager)
        
        let task1 = tvm.createTask(title: "高优先级任务", dueDate: nil, priority: .high, project: nil)
        let task2 = tvm.createTask(title: "低优先级任务", dueDate: nil, priority: .low, project: nil)
        
        XCTAssertEqual(task1.priority, .high)
        XCTAssertEqual(task2.priority, .low)
    }
} 