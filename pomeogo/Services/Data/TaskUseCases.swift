import Foundation

// MARK: - 任务用例服务
class TaskUseCases {
    private let taskRepository: any TaskRepository
    private let projectRepository: any ProjectRepository
    private let epicRepository: any EpicRepository
    
    init(taskRepository: any TaskRepository, projectRepository: any ProjectRepository, epicRepository: any EpicRepository) {
        self.taskRepository = taskRepository
        self.projectRepository = projectRepository
        self.epicRepository = epicRepository
    }
    
    // MARK: - 任务创建用例
    
    func createTask(
        title: String,
        description: String? = nil,
        priority: TaskPriority = .normal,
        status: TaskStatus = .todo,
        dueDate: Date? = nil,
        projectId: UUID? = nil,
        epicId: UUID? = nil,
        tagIds: [UUID] = [],
        estimatedHours: Double? = nil,
        assignee: String? = nil
    ) async throws -> XTask {
        // 验证项目存在性
        if let projectId = projectId {
            guard try await projectRepository.exists(id: projectId) else {
                throw TaskUseCaseError.projectNotFound(projectId)
            }
        }
        
        // 验证史诗存在性
        if let epicId = epicId {
            guard try await epicRepository.exists(id: epicId) else {
                throw TaskUseCaseError.epicNotFound(epicId)
            }
        }
        
        // 创建任务
        let task = XTask(
            title: title,
            priority: priority,
            status: status,
            projectId: projectId,
            epicId: epicId,
            tagIds: tagIds,
            notes: description,
            dueDate: dueDate,
            estimatedHours: estimatedHours,
            assignee: assignee
        )
        
        return try await taskRepository.create(task)
    }
    
    // MARK: - 任务更新用例
    
    func updateTaskStatus(_ taskId: UUID, status: TaskStatus) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        task.status = status
        
        // 如果标记为完成，设置完成时间
        if status == .completed && !task.isCompleted {
            task.isCompleted = true
            task.completedAt = Date()
        } else if status != .completed && task.isCompleted {
            task.isCompleted = false
            task.completedAt = nil
        }
        
        return try await taskRepository.update(task)
    }
    
    func updateTaskPriority(_ taskId: UUID, priority: TaskPriority) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        task.priority = priority
        return try await taskRepository.update(task)
    }
    
    func assignXTask(_ taskId: UUID, to assignee: String) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        task.assignee = assignee
        return try await taskRepository.update(task)
    }
    
    func moveTask(_ taskId: UUID, toProject projectId: UUID?) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        // 验证目标项目存在性
        if let projectId = projectId {
            guard try await projectRepository.exists(id: projectId) else {
                throw TaskUseCaseError.projectNotFound(projectId)
            }
        }
        
        task.projectId = projectId
        return try await taskRepository.update(task)
    }
    
    func moveTask(_ taskId: UUID, toEpic epicId: UUID?) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        // 验证目标史诗存在性
        if let epicId = epicId {
            guard try await epicRepository.exists(id: epicId) else {
                throw TaskUseCaseError.epicNotFound(epicId)
            }
        }
        
        task.epicId = epicId
        return try await taskRepository.update(task)
    }
    
    // MARK: - 任务查询用例
    
    func getTasksByProject(_ projectId: UUID) async throws -> [XTask] {
        guard try await projectRepository.exists(id: projectId) else {
            throw TaskUseCaseError.projectNotFound(projectId)
        }
        
        return try await taskRepository.getTasksForProject(projectId)
    }
    
    func getTasksByEpic(_ epicId: UUID) async throws -> [XTask] {
        guard try await epicRepository.exists(id: epicId) else {
            throw TaskUseCaseError.epicNotFound(epicId)
        }
        
        return try await taskRepository.getTasksForEpic(epicId)
    }
    
    func getTasksByAssignee(_ assignee: String) async throws -> [XTask] {
        return try await taskRepository.getTasksByAssignee(assignee)
    }
    
    func getOverdueTasks() async throws -> [XTask] {
        return try await taskRepository.getOverdueTasks()
    }
    
    func getTasksDueToday() async throws -> [XTask] {
        let calendar = Calendar.current
        let today = Date()
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await taskRepository.getTasksDueBetween(startOfDay, endOfDay)
    }
    
    func getTasksDueThisWeek() async throws -> [XTask] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
        
        return try await taskRepository.getTasksDueBetween(startOfWeek, endOfWeek)
    }
    
    // MARK: - 任务统计用例
    
    func getTaskStatistics() async throws -> TaskStatistics {
        let allTasks = try await taskRepository.readAll()
        
        let totalTasks = allTasks.count
        let completedTasks = allTasks.filter { $0.isCompleted }.count
        let pendingTasks = totalTasks - completedTasks
        let overdueTasks = try await taskRepository.getOverdueTasks().count
        
        let statusCounts = try await taskRepository.getTaskCountByStatus()
        let priorityCounts = try await taskRepository.getTaskCountByPriority()
        
        return TaskStatistics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            pendingTasks: pendingTasks,
            overdueTasks: overdueTasks,
            statusCounts: statusCounts,
            priorityCounts: priorityCounts
        )
    }
    
    func getProjectTaskStatistics(_ projectId: UUID) async throws -> TaskStatistics {
        guard try await projectRepository.exists(id: projectId) else {
            throw TaskUseCaseError.projectNotFound(projectId)
        }
        
        let projectTasks = try await taskRepository.getTasksForProject(projectId)
        
        let totalTasks = projectTasks.count
        let completedTasks = projectTasks.filter { $0.isCompleted }.count
        let pendingTasks = totalTasks - completedTasks
        let overdueTasks = projectTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }.count
        
        var statusCounts: [TaskStatus: Int] = [:]
        var priorityCounts: [TaskPriority: Int] = [:]
        
        for task in projectTasks {
            statusCounts[task.status, default: 0] += 1
            priorityCounts[task.priority, default: 0] += 1
        }
        
        return TaskStatistics(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            pendingTasks: pendingTasks,
            overdueTasks: overdueTasks,
            statusCounts: statusCounts,
            priorityCounts: priorityCounts
        )
    }
    
    // MARK: - 任务依赖用例
    
    func addTaskDependency(_ taskId: UUID, dependsOn dependencyId: UUID) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        guard try await taskRepository.exists(id: dependencyId) else {
            throw TaskUseCaseError.taskNotFound(dependencyId)
        }
        
        // 检查循环依赖
        if taskId == dependencyId {
            throw TaskUseCaseError.circularDependency
        }
        
        if !task.dependencyIds.contains(dependencyId) {
            task.dependencyIds.append(dependencyId)
        }
        
        return try await taskRepository.update(task)
    }
    
    func removeTaskDependency(_ taskId: UUID, dependencyId: UUID) async throws -> XTask {
        guard var task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        task.dependencyIds.removeAll { $0 == dependencyId }
        return try await taskRepository.update(task)
    }
    
    func getTaskDependencies(_ taskId: UUID) async throws -> [XTask] {
        guard let task = try await taskRepository.read(id: taskId) else {
            throw TaskUseCaseError.taskNotFound(taskId)
        }
        
        var dependencies: [XTask] = []
        for dependencyId in task.dependencyIds {
            if let dependency = try await taskRepository.read(id: dependencyId) {
                dependencies.append(dependency)
            }
        }
        
        return dependencies
    }
}

// MARK: - 任务统计模型
struct TaskStatistics {
    let totalTasks: Int
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let statusCounts: [TaskStatus: Int]
    let priorityCounts: [TaskPriority: Int]
    
    var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    var overdueRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(overdueTasks) / Double(totalTasks)
    }
}

// MARK: - 任务用例错误
enum TaskUseCaseError: Error, LocalizedError {
    case taskNotFound(UUID)
    case projectNotFound(UUID)
    case epicNotFound(UUID)
    case circularDependency
    case invalidTaskData(String)
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "任务未找到: \(id)"
        case .projectNotFound(let id):
            return "项目未找到: \(id)"
        case .epicNotFound(let id):
            return "史诗未找到: \(id)"
        case .circularDependency:
            return "检测到循环依赖"
        case .invalidTaskData(let message):
            return "无效的任务数据: \(message)"
        }
    }
} 