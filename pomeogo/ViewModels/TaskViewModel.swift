import Foundation
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    private let dataManager: DataManager
    private let taskUseCases: TaskUseCases
    @Published var tasks: [XTask] = []
    @Published var filteredTasks: [XTask] = []
    @Published var selectedTask: XTask?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Filter States
    @Published var showCompleted = false
    @Published var selectedPriority: TaskPriority?
    @Published var selectedStatus: TaskStatus?
    @Published var selectedTags: Set<UUID> = []
    @Published var searchText = ""
    
    init(dataManager: DataManager = DataManager.shared) {
        self.dataManager = dataManager
        self.taskUseCases = TaskUseCases(
            taskRepository: TaskRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            projectRepository: ProjectRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            epicRepository: EpicRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager())
        )
        setupBindings()
        Task {
            await loadTasks()
        }
    }
    
    private func setupBindings() {
        Publishers.CombineLatest4($showCompleted, $selectedPriority, $selectedStatus, $searchText)
            .combineLatest($selectedTags)
            .sink { [weak self] arg0, tags in
                guard let self = self else { return }
                let (showCompleted, priority, status, searchText) = arg0
                self.applyFilters(showCompleted: showCompleted, priority: priority, status: status, searchText: searchText, tags: tags)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 任务管理
    
    func createTask(title: String, dueDate: Date? = nil, priority: TaskPriority = .normal, projectId: UUID? = nil) async throws -> XTask {
        let task = try await taskUseCases.createTask(
            title: title,
            priority: priority,
            dueDate: dueDate,
            projectId: projectId
        )
        
        tasks.append(task)
        applyFilters()
        
        return task
    }
    
    func createTaskInEpic(title: String, dueDate: Date? = nil, priority: TaskPriority = .normal, epicId: UUID? = nil) async throws -> XTask {
        let task = try await taskUseCases.createTask(
            title: title,
            priority: priority,
            dueDate: dueDate,
            epicId: epicId
        )
        
        tasks.append(task)
        applyFilters()
        
        return task
    }
    
    func updateTask(_ task: XTask) async throws {
        let updatedTask = try await taskUseCases.updateTaskStatus(task.id, status: task.status)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    func deleteTask(_ task: XTask) async throws {
        let deleted = try await dataManager.deleteTask(task)
        
        if deleted {
            tasks.removeAll { $0.id == task.id }
            if selectedTask?.id == task.id {
                selectedTask = nil
            }
            applyFilters()
        }
    }
    
    func moveTask(_ task: XTask, to projectId: UUID?) async throws {
        let updatedTask = try await taskUseCases.moveTask(task.id, toProject: projectId)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    // MARK: - Task Status Management
    
    func completeTask(_ task: XTask) async throws {
        let updatedTask = try await taskUseCases.updateTaskStatus(task.id, status: .completed)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    func reopenTask(_ task: XTask) async throws {
        let updatedTask = try await taskUseCases.updateTaskStatus(task.id, status: .todo)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    func updateTaskStatus(_ task: XTask, status: TaskStatus) async throws {
        let updatedTask = try await taskUseCases.updateTaskStatus(task.id, status: status)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    // MARK: - Task Dependencies
    
    func addTaskDependency(_ task: XTask, dependsOn dependencyId: UUID) async throws {
        let updatedTask = try await taskUseCases.addTaskDependency(task.id, dependsOn: dependencyId)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    func removeTaskDependency(_ task: XTask, dependencyId: UUID) async throws {
        let updatedTask = try await taskUseCases.removeTaskDependency(task.id, dependencyId: dependencyId)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
        applyFilters()
    }
    
    // MARK: - Task Queries
    
    /// 获取顶层任务（没有父任务、没有项目、没有Epic的任务）
    var topLevelTasks: [XTask] {
        return filteredTasks.filter { task in
            task.parentId == nil && task.projectId == nil && task.epicId == nil
        }
    }
    
    /// 获取所有顶层任务（包括未过滤的）
    var allTopLevelTasks: [XTask] {
        return tasks.filter { task in
            task.parentId == nil && task.projectId == nil && task.epicId == nil
        }
    }
    
    // MARK: - Filtering
    
    private func applyFilters(showCompleted: Bool? = nil,
                            priority: TaskPriority? = nil,
                            status: TaskStatus? = nil,
                            searchText: String? = nil,
                            tags: Set<UUID>? = nil) {
        var filtered = tasks
        
        // 完成状态过滤
        if let showCompleted = showCompleted, !showCompleted {
            filtered = filtered.filter { !$0.isCompleted }
        } else if let showCompleted = showCompleted, showCompleted {
            filtered = filtered.filter { $0.isCompleted }
        }
        
        // 优先级过滤
        if let priority = priority {
            filtered = filtered.filter { $0.priority == priority }
        }
        
        // 状态过滤
        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }
        
        // 标签过滤
        if let tags = tags, !tags.isEmpty {
            filtered = filtered.filter { task in
                !Set(task.tagIds).isDisjoint(with: tags)
            }
        }
        
        // 搜索文本过滤
        if let searchText = searchText, !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        filteredTasks = filtered
    }
    
    // 便捷方法：使用当前状态重新应用过滤器
    private func applyFilters() {
        applyFilters(
            showCompleted: showCompleted,
            priority: selectedPriority,
            status: selectedStatus,
            searchText: searchText,
            tags: selectedTags
        )
    }
    
    // MARK: - Loading & Refreshing
    
    func loadTasks() async {
        do {
            let loadedTasks = try await dataManager.tasks
            await MainActor.run {
                self.tasks = loadedTasks
                self.applyFilters()
            }
        } catch {
            print("加载任务失败: \(error)")
        }
    }
    
    func refreshTasks() {
        Task {
            await loadTasks()
        }
    }
    
    // MARK: - Statistics
    
    var completionRate: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(tasks.filter { $0.isCompleted }.count) / Double(tasks.count)
    }
    
    var overdueTasks: [XTask] {
        tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }
    }
    
    func tasksGroupedByStatus() -> [TaskStatus: [XTask]] {
        Dictionary(grouping: filteredTasks) { $0.status }
    }
    
    func tasksGroupedByPriority() -> [TaskPriority: [XTask]] {
        Dictionary(grouping: filteredTasks) { $0.priority }
    }
    
    // MARK: - Checklist Management
    
    func getChecklistItems(for itemIds: [UUID]) -> [ChecklistItem] {
        // 这里应该从数据管理器获取ChecklistItem
        // 暂时返回空数组，需要实现ChecklistItem的数据管理
        return []
    }
    
    func updateChecklistItem(_ item: ChecklistItem) async throws {
        // 这里应该更新ChecklistItem
        // 暂时为空实现，需要实现ChecklistItem的数据管理
    }
    
    func deleteChecklistItem(_ item: ChecklistItem) async throws {
        // 这里应该删除ChecklistItem
        // 暂时为空实现，需要实现ChecklistItem的数据管理
    }
    
    func addChecklistItem(_ item: ChecklistItem, to task: XTask) async throws {
        // 这里应该添加ChecklistItem到任务
        // 暂时为空实现，需要实现ChecklistItem的数据管理
    }
    
    // MARK: - Subtask Management
    
    func getSubtasks(for taskIds: [UUID]) -> [XTask] {
        return tasks.filter { taskIds.contains($0.id) }
    }
} 