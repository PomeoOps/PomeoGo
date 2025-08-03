import Foundation

// MARK: - TaskRepository实现
class TaskRepositoryImpl: TaskRepository {
    private let storage: StorageService
    private let cache: CacheManager
    
    init(storage: StorageService, cache: CacheManager) {
        self.storage = storage
        self.cache = cache
    }
    
    // MARK: - 基本CRUD操作
    
    func create(_ entity: XTask) async throws -> XTask {
        var task = entity
        task.updatedAt = Date()
        
        // 保存到存储
        try await storage.save(task, forKey: "task_\(task.id.uuidString)")
        
        // 更新缓存
        cache.setValue(task, forKey: "task_\(task.id.uuidString)")
        
        return task
    }
    
    func read(id: UUID) async throws -> XTask? {
        // 先从缓存获取
        if let cachedTask: XTask = cache.getValue(forKey: "task_\(id.uuidString)") {
            return cachedTask
        }
        
        // 从存储获取
        guard let task: XTask = try await storage.load(forKey: "task_\(id.uuidString)") else {
            return nil
        }
        
        // 更新缓存
        cache.setValue(task, forKey: "task_\(id.uuidString)")
        
        return task
    }
    
    func update(_ entity: XTask) async throws -> XTask {
        var task = entity
        task.updatedAt = Date()
        task.version += 1
        
        // 保存到存储
        try await storage.save(task, forKey: "task_\(task.id.uuidString)")
        
        // 更新缓存
        cache.setValue(task, forKey: "task_\(task.id.uuidString)")
        
        return task
    }
    
    func delete(id: UUID) async throws -> Bool {
        // 从存储删除
        let deleted = try await storage.delete(forKey: "task_\(id.uuidString)")
        
        // 从缓存删除
        cache.removeValue(forKey: "task_\(id.uuidString)")
        
        return deleted
    }
    
    func delete(_ entity: XTask) async throws -> Bool {
        return try await delete(id: entity.id)
    }
    
    // MARK: - 批量操作
    
    func readAll() async throws -> [XTask] {
        // 获取所有任务键
        let allKeys = try await storage.getAllKeys()
        let keys = allKeys.filter { $0.hasPrefix("task_") }
        
        // 批量加载任务
        var tasks: [XTask] = []
        for key in keys {
            if let task: XTask = try await storage.load(forKey: key) {
                tasks.append(task)
            }
        }
        
        return tasks.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func createMany(_ entities: [XTask]) async throws -> [XTask] {
        var createdTasks: [XTask] = []
        
        for entity in entities {
            let createdTask = try await create(entity)
            createdTasks.append(createdTask)
        }
        
        return createdTasks
    }
    
    func updateMany(_ entities: [XTask]) async throws -> [XTask] {
        var updatedTasks: [XTask] = []
        
        for entity in entities {
            let updatedTask = try await update(entity)
            updatedTasks.append(updatedTask)
        }
        
        return updatedTasks
    }
    
    func deleteMany(ids: [UUID]) async throws -> Bool {
        var allDeleted = true
        
        for id in ids {
            let deleted = try await delete(id: id)
            if !deleted {
                allDeleted = false
            }
        }
        
        return allDeleted
    }
    
    // MARK: - 查询操作
    
    func count() async throws -> Int {
        let allKeys = try await storage.getAllKeys()
        let keys = allKeys.filter { $0.hasPrefix("task_") }
        return keys.count
    }
    
    func exists(id: UUID) async throws -> Bool {
        return try await storage.exists(forKey: "task_\(id.uuidString)")
    }
    
    // MARK: - 任务特定查询
    
    func getTasksForProject(_ projectId: UUID) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.projectId == projectId }
    }
    
    func getTasksForEpic(_ epicId: UUID) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.epicId == epicId }
    }
    
    func getTasksWithTag(_ tagId: UUID) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.tagIds.contains(tagId) }
    }
    
    func getCompletedTasks() async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.isCompleted }
    }
    
    func getPendingTasks() async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { !$0.isCompleted }
    }
    
    func getOverdueTasks() async throws -> [XTask] {
        let allTasks = try await readAll()
        let now = Date()
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < now
        }
    }
    
    func getTasksByStatus(_ status: TaskStatus) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.status == status }
    }
    
    func getTasksByPriority(_ priority: TaskPriority) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.priority == priority }
    }
    
    func getTasksByAssignee(_ assignee: String) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { $0.assignee == assignee }
    }
    
    func getTasksWithDependencies() async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { !$0.dependencyIds.isEmpty }
    }
    
    func getTasksDueBetween(_ startDate: Date, _ endDate: Date) async throws -> [XTask] {
        let allTasks = try await readAll()
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= startDate && dueDate <= endDate
        }
    }
    
    // MARK: - 统计查询
    
    func getTaskCountByStatus() async throws -> [TaskStatus: Int] {
        let allTasks = try await readAll()
        var counts: [TaskStatus: Int] = [:]
        
        for task in allTasks {
            counts[task.status, default: 0] += 1
        }
        
        return counts
    }
    
    func getTaskCountByPriority() async throws -> [TaskPriority: Int] {
        let allTasks = try await readAll()
        var counts: [TaskPriority: Int] = [:]
        
        for task in allTasks {
            counts[task.priority, default: 0] += 1
        }
        
        return counts
    }
    
    func getTaskCountByProject() async throws -> [UUID: Int] {
        let allTasks = try await readAll()
        var counts: [UUID: Int] = [:]
        
        for task in allTasks {
            if let projectId = task.projectId {
                counts[projectId, default: 0] += 1
            }
        }
        
        return counts
    }
    
    func getTaskCountByEpic() async throws -> [UUID: Int] {
        let allTasks = try await readAll()
        var counts: [UUID: Int] = [:]
        
        for task in allTasks {
            if let epicId = task.epicId {
                counts[epicId, default: 0] += 1
            }
        }
        
        return counts
    }
} 