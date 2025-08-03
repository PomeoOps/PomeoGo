import XCTest
@testable import pomeogo

final class DataManagerIntegrationTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUpWithError() throws {
        dataManager = DataManager.shared
    }
    
    override func tearDownWithError() throws {
        try await dataManager.clearAllData()
    }
    
    func testTaskLifecycle() async throws {
        // Given
        let taskTitle = "集成测试任务"
        let taskDescription = "这是一个集成测试任务"
        
        // When - Create
        let createdTask = try await dataManager.createTask(XTask(
            title: taskTitle,
            notes: taskDescription,
            priority: .high,
            status: .inProgress
        ))
        
        // Then - Verify creation
        XCTAssertEqual(createdTask.title, taskTitle)
        XCTAssertEqual(createdTask.notes, taskDescription)
        XCTAssertEqual(createdTask.priority, .high)
        XCTAssertEqual(createdTask.status, .inProgress)
        XCTAssertNotNil(createdTask.id)
        
        // When - Read
        let readTask = try await dataManager.getXTask(by: createdTask.id)
        
        // Then - Verify read
        XCTAssertNotNil(readTask)
        XCTAssertEqual(readTask?.title, taskTitle)
        XCTAssertEqual(readTask?.notes, taskDescription)
        
        // When - Update
        var updatedTask = createdTask
        updatedTask.title = "更新后的任务"
        updatedTask.status = .completed
        let resultTask = try await dataManager.updateTask(updatedTask)
        
        // Then - Verify update
        XCTAssertEqual(resultTask.title, "更新后的任务")
        XCTAssertEqual(resultTask.status, .completed)
        XCTAssertGreaterThan(resultTask.version, createdTask.version)
        
        // When - Delete
        let deleted = try await dataManager.deleteTask(resultTask)
        
        // Then - Verify deletion
        XCTAssertTrue(deleted)
        
        let deletedTask = try await dataManager.getXTask(by: resultTask.id)
        XCTAssertNil(deletedTask)
    }
    
    func testProjectLifecycle() async throws {
        // Given
        let projectName = "集成测试项目"
        let projectDescription = "这是一个集成测试项目"
        
        // When - Create
        let createdProject = try await dataManager.createProject(Project(
            name: projectName,
            projectDescription: projectDescription,
            color: "#FF0000"
        ))
        
        // Then - Verify creation
        XCTAssertEqual(createdProject.name, projectName)
        XCTAssertEqual(createdProject.projectDescription, projectDescription)
        XCTAssertEqual(createdProject.color, "#FF0000")
        XCTAssertNotNil(createdProject.id)
        
        // When - Read
        let readProject = try await dataManager.getProject(by: createdProject.id)
        
        // Then - Verify read
        XCTAssertNotNil(readProject)
        XCTAssertEqual(readProject?.name, projectName)
        
        // When - Update
        var updatedProject = createdProject
        updatedProject.name = "更新后的项目"
        updatedProject.isCompleted = true
        let resultProject = try await dataManager.updateProject(updatedProject)
        
        // Then - Verify update
        XCTAssertEqual(resultProject.name, "更新后的项目")
        XCTAssertTrue(resultProject.isCompleted)
        XCTAssertGreaterThan(resultProject.version, createdProject.version)
        
        // When - Delete
        let deleted = try await dataManager.deleteProject(resultProject)
        
        // Then - Verify deletion
        XCTAssertTrue(deleted)
        
        let deletedProject = try await dataManager.getProject(by: resultProject.id)
        XCTAssertNil(deletedProject)
    }
    
    func testEpicLifecycle() async throws {
        // Given
        let epicName = "集成测试史诗"
        let epicDescription = "这是一个集成测试史诗"
        
        // When - Create
        let createdEpic = try await dataManager.createEpic(Epic(
            name: epicName,
            epicDescription: epicDescription,
            color: "#00FF00"
        ))
        
        // Then - Verify creation
        XCTAssertEqual(createdEpic.name, epicName)
        XCTAssertEqual(createdEpic.epicDescription, epicDescription)
        XCTAssertEqual(createdEpic.color, "#00FF00")
        XCTAssertNotNil(createdEpic.id)
        
        // When - Read
        let readEpic = try await dataManager.getEpic(by: createdEpic.id)
        
        // Then - Verify read
        XCTAssertNotNil(readEpic)
        XCTAssertEqual(readEpic?.name, epicName)
        
        // When - Update
        var updatedEpic = createdEpic
        updatedEpic.name = "更新后的史诗"
        updatedEpic.isArchived = true
        let resultEpic = try await dataManager.updateEpic(updatedEpic)
        
        // Then - Verify update
        XCTAssertEqual(resultEpic.name, "更新后的史诗")
        XCTAssertTrue(resultEpic.isArchived)
        XCTAssertGreaterThan(resultEpic.version, createdEpic.version)
        
        // When - Delete
        let deleted = try await dataManager.deleteEpic(resultEpic)
        
        // Then - Verify deletion
        XCTAssertTrue(deleted)
        
        let deletedEpic = try await dataManager.getEpic(by: resultEpic.id)
        XCTAssertNil(deletedEpic)
    }
    
    func testTaskProjectRelationship() async throws {
        // Given
        let project = try await dataManager.createProject(Project(name: "测试项目"))
        let task = XTask(title: "项目任务", projectId: project.id)
        
        // When
        let createdTask = try await dataManager.createTask(task)
        
        // Then
        XCTAssertEqual(createdTask.projectId, project.id)
        
        // When - Get tasks for project
        let projectTasks = try await dataManager.getTasksForProject(project.id)
        
        // Then
        XCTAssertEqual(projectTasks.count, 1)
        XCTAssertEqual(projectTasks.first?.title, "项目任务")
    }
    
    func testTaskEpicRelationship() async throws {
        // Given
        let epic = try await dataManager.createEpic(Epic(name: "测试史诗"))
        let task = XTask(title: "史诗任务", epicId: epic.id)
        
        // When
        let createdTask = try await dataManager.createTask(task)
        
        // Then
        XCTAssertEqual(createdTask.epicId, epic.id)
        
        // When - Get tasks for epic
        let epicTasks = try await dataManager.getTasksForEpic(epic.id)
        
        // Then
        XCTAssertEqual(epicTasks.count, 1)
        XCTAssertEqual(epicTasks.first?.title, "史诗任务")
    }
    
    func testTaskStatistics() async throws {
        // Given
        let task1 = try await dataManager.createTask(XTask(title: "已完成任务", isCompleted: true))
        let task2 = try await dataManager.createTask(XTask(title: "未完成任务", isCompleted: false))
        let task3 = try await dataManager.createTask(XTask(title: "另一个已完成任务", isCompleted: true))
        
        // When
        let statusCounts = try await dataManager.getTaskCountByStatus()
        let priorityCounts = try await dataManager.getTaskCountByPriority()
        
        // Then
        XCTAssertEqual(statusCounts[.completed], 2)
        XCTAssertEqual(statusCounts[.todo], 1)
        XCTAssertEqual(priorityCounts[.normal], 3) // 默认优先级
    }
    
    func testProjectStatistics() async throws {
        // Given
        let project1 = try await dataManager.createProject(Project(name: "活跃项目", isArchived: false))
        let project2 = try await dataManager.createProject(Project(name: "归档项目", isArchived: true))
        let project3 = try await dataManager.createProject(Project(name: "另一个活跃项目", isArchived: false))
        
        // When
        let activeProjects = try await dataManager.getActiveProjects()
        let archivedProjects = try await dataManager.getArchivedProjects()
        
        // Then
        XCTAssertEqual(activeProjects.count, 2)
        XCTAssertEqual(archivedProjects.count, 1)
    }
    
    func testEpicStatistics() async throws {
        // Given
        let epic1 = try await dataManager.createEpic(Epic(name: "活跃史诗", isArchived: false))
        let epic2 = try await dataManager.createEpic(Epic(name: "归档史诗", isArchived: true))
        
        // When
        let activeEpics = try await dataManager.getActiveEpics()
        let archivedEpics = try await dataManager.getArchivedEpics()
        
        // Then
        XCTAssertEqual(activeEpics.count, 1)
        XCTAssertEqual(archivedEpics.count, 1)
    }
    
    func testDataPersistence() async throws {
        // Given
        let task = try await dataManager.createTask(XTask(title: "持久化测试任务"))
        let project = try await dataManager.createProject(Project(name: "持久化测试项目"))
        let epic = try await dataManager.createEpic(Epic(name: "持久化测试史诗"))
        
        // When - Create new data manager instance (simulating app restart)
        let newDataManager = DataManager.shared
        
        // Then - Verify data persistence
        let persistedTask = try await newDataManager.getXTask(by: task.id)
        let persistedProject = try await newDataManager.getProject(by: project.id)
        let persistedEpic = try await newDataManager.getEpic(by: epic.id)
        
        XCTAssertNotNil(persistedTask)
        XCTAssertNotNil(persistedProject)
        XCTAssertNotNil(persistedEpic)
        XCTAssertEqual(persistedTask?.title, "持久化测试任务")
        XCTAssertEqual(persistedProject?.name, "持久化测试项目")
        XCTAssertEqual(persistedEpic?.name, "持久化测试史诗")
    }
    
    func testConcurrentOperations() async throws {
        // Given
        let taskCount = 10
        
        // When - Create tasks concurrently
        let tasks = try await withThrowingTaskGroup(of: XTaskself) { group in
            for i in 0..<taskCount {
                group.addTask {
                    try await self.dataManager.createTask(XTask(title: "并发任务 \(i)"))
                }
            }
            
            var results: [XTask] = []
            for try await task in group {
                results.append(task)
            }
            return results
        }
        
        // Then
        XCTAssertEqual(tasks.count, taskCount)
        
        // When - Read all tasks
        let allTasks = try await dataManager.tasks
        
        // Then
        XCTAssertEqual(allTasks.count, taskCount)
    }
} 