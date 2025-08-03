import Foundation
import Combine

@MainActor
class EpicViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var tasks: [XTask] = []
    @Published var selectedProject: Project?
    
    private let epic: Epic
    private let dataManager: DataManager
    private let projectUseCases: ProjectUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(epic: Epic, dataManager: DataManager = DataManager()) {
        self.epic = epic
        self.dataManager = dataManager
        self.projectUseCases = ProjectUseCases(
            projectRepository: ProjectRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            taskRepository: TaskRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            epicRepository: EpicRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager())
        )
        loadData()
    }
    
    // MARK: - 数据加载
    
    func loadData() {
        _Concurrency.Task {
            do {
                let loadedProjects = try await projectUseCases.getProjectsForEpic(epic.id)
                await MainActor.run {
                    self.projects = loadedProjects
                }
            } catch {
                print("加载项目数据失败: \(error)")
            }
        }
    }
    
    // MARK: - 项目管理
    
    func addProject(_ project: Project) async throws {
        let updatedProject = try await projectUseCases.moveProject(project.id, toEpic: epic.id)
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updatedProject
        } else {
            projects.append(updatedProject)
        }
    }
    
    func removeProject(_ project: Project) async throws {
        let updatedProject = try await projectUseCases.moveProject(project.id, toEpic: nil)
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updatedProject
        }
    }
    
    // MARK: - 任务管理
    
    func addTask(_ task: XTask) async throws {
        let updatedTask = try await dataManager.updateTask(task)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        } else {
            tasks.append(updatedTask)
        }
    }
    
    func removeTask(_ task: XTask) async throws {
        let updatedTask = try await dataManager.updateTask(task)
        
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = updatedTask
        }
    }
    
    // MARK: - 统计
    
    func getEpicProgress() async -> Double {
        do {
            let epicProjects = try await projectUseCases.getProjectsForEpic(epic.id)
            var allTasks: [XTask] = []
            
            for project in epicProjects {
                let projectTasks = try await projectUseCases.getProjectTasks(project.id)
                allTasks.append(contentsOf: projectTasks)
            }
            
            guard !allTasks.isEmpty else { return 0 }
            return Double(allTasks.filter { $0.isCompleted }.count) / Double(allTasks.count)
        } catch {
            return 0
        }
    }
    
    func getProjectCount() -> Int {
        return projects.count
    }
    
    func getTaskCount() -> Int {
        return tasks.count
    }
} 
