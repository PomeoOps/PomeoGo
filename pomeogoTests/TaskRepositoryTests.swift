import XCTest
@testable import pomeogo

final class TaskRepositoryTests: XCTestCase {
    var taskRepository: TaskRepositoryImpl!
    var storage: UserDefaultsStorage!
    var cache: CacheManager!
    
    override func setUpWithError() throws {
        storage = UserDefaultsStorage()
        cache = CacheManager()
        taskRepository = TaskRepositoryImpl(storage: storage, cache: cache)
    }
    
    override func tearDownWithError() throws {
        try await storage.clear()
        await cache.clear()
        taskRepository = nil
        storage = nil
        cache = nil
    }
    
    func testCreateXTask() async throws {
        // Given
        let task = XTask(title: "测试任务")
        
        // When
        let createdTask = try await taskRepository.create(task)
        
        // Then
        XCTAssertEqual(createdTask.title, "测试任务")
        XCTAssertNotNil(createdTask.id)
        XCTAssertEqual(createdTask.priority, .normal)
        XCTAssertEqual(createdTask.status, .todo)
        XCTAssertFalse(createdTask.isCompleted)
    }
    
    func testReadXTask() async throws {
        // Given
        let task = XTask(title: "测试任务")
        let createdTask = try await taskRepository.create(task)
        
        // When
        let readTask = try await taskRepository.read(id: createdTask.id)
        
        // Then
        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.title, "测试任务")
        XCTAssertEqual(readTask?.id, createdTask.id)
    }
    
    func testUpdateXTask() async throws {
        // Given
        let task = XTask(title: "原始任务")
        let createdTask = try await taskRepository.create(task)
        
        // When
        var updatedTask = createdTask
        updatedTask.title = "更新后的任务"
        updatedTask.priority = .high
        let result = try await taskRepository.update(updatedTask)
        
        // Then
        XCTAssertEqual(result.title, "更新后的任务")
        XCTAssertEqual(result.priority, .high)
        XCTAssertGreaterThan(result.version, createdTask.version)
    }
    
    func testDeleteXTask() async throws {
        // Given
        let task = XTask(title: "要删除的任务")
        let createdTask = try await taskRepository.create(task)
        
        // When
        let deleted = try await taskRepository.delete(id: createdTask.id)
        
        // Then
        XCTAssertTrue(deleted)
        
        let readTask = try await taskRepository.read(id: createdTask.id)
        XCTAssertNil(readTask)
    }
    
    func testReadAllTasks() async throws {
        // Given
        let task1 = XTask(title: "任务1")
        let task2 = XTask(title: "任务2")
        let task3 = XTask(title: "任务3")
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        
        // When
        let allTasks = try await taskRepository.readAll()
        
        // Then
        XCTAssertEqual(allTasks.count, 3)
        XCTAssertTrue(allTasks.contains { $0.title == "任务1" })
        XCTAssertTrue(allTasks.contains { $0.title == "任务2" })
        XCTAssertTrue(allTasks.contains { $0.title == "任务3" })
    }
    
    func testGetCompletedTasks() async throws {
        // Given
        let task1 = XTask(title: "已完成任务", isCompleted: true)
        let task2 = XTask(title: "未完成任务", isCompleted: false)
        let task3 = XTask(title: "另一个已完成任务", isCompleted: true)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        
        // When
        let completedTasks = try await taskRepository.getCompletedTasks()
        
        // Then
        XCTAssertEqual(completedTasks.count, 2)
        XCTAssertTrue(completedTasks.allSatisfy { $0.isCompleted })
    }
    
    func testGetPendingTasks() async throws {
        // Given
        let task1 = XTask(title: "已完成任务", isCompleted: true)
        let task2 = XTask(title: "未完成任务", isCompleted: false)
        let task3 = XTask(title: "另一个未完成任务", isCompleted: false)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        
        // When
        let pendingTasks = try await taskRepository.getPendingTasks()
        
        // Then
        XCTAssertEqual(pendingTasks.count, 2)
        XCTAssertTrue(pendingTasks.allSatisfy { !$0.isCompleted })
    }
    
    func testGetTasksByStatus() async throws {
        // Given
        let task1 = XTask(title: "待办任务", status: .todo)
        let task2 = XTask(title: "进行中任务", status: .inProgress)
        let task3 = XTask(title: "另一个待办任务", status: .todo)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        
        // When
        let todoTasks = try await taskRepository.getTasksByStatus(.todo)
        
        // Then
        XCTAssertEqual(todoTasks.count, 2)
        XCTAssertTrue(todoTasks.allSatisfy { $0.status == .todo })
    }
    
    func testGetTasksByPriority() async throws {
        // Given
        let task1 = XTask(title: "高优先级任务", priority: .high)
        let task2 = XTask(title: "普通任务", priority: .normal)
        let task3 = XTask(title: "另一个高优先级任务", priority: .high)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        
        // When
        let highPriorityTasks = try await taskRepository.getTasksByPriority(.high)
        
        // Then
        XCTAssertEqual(highPriorityTasks.count, 2)
        XCTAssertTrue(highPriorityTasks.allSatisfy { $0.priority == .high })
    }
    
    func testGetOverdueTasks() async throws {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let overdueTask = XTask(title: "逾期任务", dueDate: yesterday, isCompleted: false)
        let futureTask = XTask(title: "未来任务", dueDate: tomorrow, isCompleted: false)
        let completedTask = XTask(title: "已完成任务", dueDate: yesterday, isCompleted: true)
        
        _ = try await taskRepository.create(overdueTask)
        _ = try await taskRepository.create(futureTask)
        _ = try await taskRepository.create(completedTask)
        
        // When
        let overdueTasks = try await taskRepository.getOverdueTasks()
        
        // Then
        XCTAssertEqual(overdueTasks.count, 1)
        XCTAssertEqual(overdueTasks.first?.title, "逾期任务")
    }
    
    func testGetTaskCountByStatus() async throws {
        // Given
        let task1 = XTask(title: "待办任务", status: .todo)
        let task2 = XTask(title: "进行中任务", status: .inProgress)
        let task3 = XTask(title: "另一个待办任务", status: .todo)
        let task4 = XTask(title: "已完成任务", status: .completed)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        _ = try await taskRepository.create(task4)
        
        // When
        let statusCounts = try await taskRepository.getTaskCountByStatus()
        
        // Then
        XCTAssertEqual(statusCounts[.todo], 2)
        XCTAssertEqual(statusCounts[.inProgress], 1)
        XCTAssertEqual(statusCounts[.completed], 1)
    }
    
    func testGetTaskCountByPriority() async throws {
        // Given
        let task1 = XTask(title: "高优先级任务", priority: .high)
        let task2 = XTask(title: "普通任务", priority: .normal)
        let task3 = XTask(title: "另一个高优先级任务", priority: .high)
        let task4 = XTask(title: "低优先级任务", priority: .low)
        
        _ = try await taskRepository.create(task1)
        _ = try await taskRepository.create(task2)
        _ = try await taskRepository.create(task3)
        _ = try await taskRepository.create(task4)
        
        // When
        let priorityCounts = try await taskRepository.getTaskCountByPriority()
        
        // Then
        XCTAssertEqual(priorityCounts[.high], 2)
        XCTAssertEqual(priorityCounts[.normal], 1)
        XCTAssertEqual(priorityCounts[.low], 1)
    }
} 