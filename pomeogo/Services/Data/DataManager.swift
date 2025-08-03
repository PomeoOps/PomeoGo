import Foundation

// MARK: - 数据管理器服务
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // 存储服务
    private let userDefaultsStorage: UserDefaultsStorage
    private let fileSystemStorage: FileSystemStorage
    private let cacheManager: CacheManager
    
    // 仓储实例
    private let taskRepository: any TaskRepository
    private let projectRepository: any ProjectRepository
    private let epicRepository: any EpicRepository
    
    // 发布的数据
    @Published var tasks: [XTask] = []
    @Published var projects: [Project] = []
    @Published var epics: [Epic] = []
    
    init() {
        // 初始化存储服务
        self.userDefaultsStorage = UserDefaultsStorage()
        self.fileSystemStorage = try! FileSystemStorage()
        self.cacheManager = CacheManager()
        
        // 初始化仓储
        self.taskRepository = TaskRepositoryImpl(storage: userDefaultsStorage, cache: cacheManager)
        self.projectRepository = ProjectRepositoryImpl(storage: userDefaultsStorage, cache: cacheManager)
        self.epicRepository = EpicRepositoryImpl(storage: userDefaultsStorage, cache: cacheManager)
        
        // 加载初始数据
        _Concurrency.Task {
            await loadInitialData()
        }
    }
    
    // MARK: - 数据加载
    
    @MainActor
    private func loadInitialData() async {
        do {
            tasks = try await taskRepository.readAll()
            projects = try await projectRepository.readAll()
            epics = try await epicRepository.readAll()
        } catch {
            print("加载初始数据失败: \(error)")
        }
    }
    
    // MARK: - 任务管理
    
    func createTask(_ task: XTask) async throws -> XTask {
        let createdTask = try await taskRepository.create(task)
        
        await MainActor.run {
            tasks.append(createdTask)
        }
        
        return createdTask
    }
    
    func updateTask(_ task: XTask) async throws -> XTask {
        let updatedTask = try await taskRepository.update(task)
        
        await MainActor.run {
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updatedTask
            }
        }
        
        return updatedTask
    }
    
    func deleteTask(_ task: XTask) async throws -> Bool {
        let deleted = try await taskRepository.delete(task)
        
        if deleted {
            await MainActor.run {
                tasks.removeAll { $0.id == task.id }
            }
        }
        
        return deleted
    }
    
    func getXTask(by id: UUID) async throws -> XTask? {
        return try await taskRepository.read(id: id)
    }
    
    func getTasksForProject(_ projectId: UUID) async throws -> [XTask] {
        return try await taskRepository.getTasksForProject(projectId)
    }
    
    func getTasksForEpic(_ epicId: UUID) async throws -> [XTask] {
        return try await taskRepository.getTasksForEpic(epicId)
    }
    
    func getCompletedTasks() async throws -> [XTask] {
        return try await taskRepository.getCompletedTasks()
    }
    
    func getPendingTasks() async throws -> [XTask] {
        return try await taskRepository.getPendingTasks()
    }
    
    func getOverdueTasks() async throws -> [XTask] {
        return try await taskRepository.getOverdueTasks()
    }
    
    // MARK: - 项目管理
    
    func createProject(_ project: Project) async throws -> Project {
        let createdProject = try await projectRepository.create(project)
        
        await MainActor.run {
            projects.append(createdProject)
        }
        
        return createdProject
    }
    
    func updateProject(_ project: Project) async throws -> Project {
        let updatedProject = try await projectRepository.update(project)
        
        await MainActor.run {
            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                projects[index] = updatedProject
            }
        }
        
        return updatedProject
    }
    
    func deleteProject(_ project: Project) async throws -> Bool {
        let deleted = try await projectRepository.delete(project)
        
        if deleted {
            await MainActor.run {
                projects.removeAll { $0.id == project.id }
            }
        }
        
        return deleted
    }
    
    func getProject(by id: UUID) async throws -> Project? {
        return try await projectRepository.read(id: id)
    }
    
    func getActiveProjects() async throws -> [Project] {
        return try await projectRepository.getActiveProjects()
    }
    
    func getArchivedProjects() async throws -> [Project] {
        return try await projectRepository.getArchivedProjects()
    }
    
    // MARK: - 史诗管理
    
    func createEpic(_ epic: Epic) async throws -> Epic {
        let createdEpic = try await epicRepository.create(epic)
        
        await MainActor.run {
            epics.append(createdEpic)
        }
        
        return createdEpic
    }
    
    func updateEpic(_ epic: Epic) async throws -> Epic {
        let updatedEpic = try await epicRepository.update(epic)
        
        await MainActor.run {
            if let index = epics.firstIndex(where: { $0.id == epic.id }) {
                epics[index] = updatedEpic
            }
        }
        
        return updatedEpic
    }
    
    func deleteEpic(_ epic: Epic) async throws -> Bool {
        let deleted = try await epicRepository.delete(epic)
        
        if deleted {
            await MainActor.run {
                epics.removeAll { $0.id == epic.id }
            }
        }
        
        return deleted
    }
    
    func getEpic(by id: UUID) async throws -> Epic? {
        return try await epicRepository.read(id: id)
    }
    
    func getActiveEpics() async throws -> [Epic] {
        return try await epicRepository.getActiveEpics()
    }
    
    func getArchivedEpics() async throws -> [Epic] {
        return try await epicRepository.getArchivedEpics()
    }
    
    // MARK: - 统计查询
    
    func getTaskCountByStatus() async throws -> [TaskStatus: Int] {
        return try await taskRepository.getTaskCountByStatus()
    }
    
    func getTaskCountByPriority() async throws -> [TaskPriority: Int] {
        return try await taskRepository.getTaskCountByPriority()
    }
    
    func getTaskCountByProject() async throws -> [UUID: Int] {
        return try await taskRepository.getTaskCountByProject()
    }
    
    func getTaskCountByEpic() async throws -> [UUID: Int] {
        return try await taskRepository.getTaskCountByEpic()
    }
    
    func getProjectCountByEpic() async throws -> [UUID: Int] {
        return try await projectRepository.getProjectCountByEpic()
    }
    
    func getProjectCountByColor() async throws -> [String: Int] {
        return try await projectRepository.getProjectCountByColor()
    }
    
    func getEpicCountByColor() async throws -> [String: Int] {
        return try await epicRepository.getEpicCountByColor()
    }
    
    // MARK: - 数据管理
    
    func clearAllData() async throws -> Bool {
        do {
            try await userDefaultsStorage.clear()
            try await fileSystemStorage.clear()
            await cacheManager.clear()
            
            await MainActor.run {
                tasks.removeAll()
                projects.removeAll()
                epics.removeAll()
            }
            
            return true
        } catch {
            print("清除所有数据失败: \(error)")
            return false
        }
    }
    
    func backupData() async throws -> Data {
        return try await userDefaultsStorage.backup()
    }
    
    func restoreData(from backup: Data) async throws {
        try await userDefaultsStorage.restore(from: backup)
        await loadInitialData()
    }
    
    func getStorageSize() async throws -> Int64 {
        let userDefaultsSize = try await userDefaultsStorage.getStorageSize()
        let fileSystemSize = try await fileSystemStorage.getStorageSize()
        return userDefaultsSize + fileSystemSize
    }
} 