import Foundation
import Combine

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var epics: [Epic] = []
    @Published var selectedProject: Project?
    @Published var selectedEpic: Epic?
    
    private let dataManager: DataManager
    private let projectUseCases: ProjectUseCases
    private var cancellables = Set<AnyCancellable>()
    
    init(dataManager: DataManager = DataManager()) {
        self.dataManager = dataManager
        self.projectUseCases = ProjectUseCases(
            projectRepository: ProjectRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            taskRepository: TaskRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager()),
            epicRepository: EpicRepositoryImpl(storage: UserDefaultsStorage(), cache: CacheManager())
        )
        loadData()
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听项目变化
        $selectedProject
            .sink { [weak self] project in
                if let project = project {
                    self?.loadTasks(for: project)
                }
            }
            .store(in: &cancellables)
        
        // 监听史诗变化
        $selectedEpic
            .sink { [weak self] epic in
                if let epic = epic {
                    self?.loadProjects(for: epic)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 数据加载
    
    func loadData() {
        _Concurrency.Task {
            do {
                let loadedProjects = try await dataManager.projects
                let loadedEpics = try await dataManager.epics
                
                await MainActor.run {
                    self.projects = loadedProjects
                    self.epics = loadedEpics
                }
            } catch {
                print("加载数据失败: \(error)")
            }
        }
    }
    
    private func loadTasks(for project: Project) {
        // 项目任务通过新的数据层加载
    }
    
    private func loadProjects(for epic: Epic) {
        // 史诗项目通过新的数据层加载
    }
    
    // MARK: - 项目管理
    
    func createProject(name: String, description: String? = nil, epicId: UUID? = nil) async throws -> Project {
        let project = try await projectUseCases.createProject(
            name: name,
            description: description,
            epicId: epicId
        )
        
        projects.append(project)
        return project
    }
    
    func updateProject(_ project: Project) async throws {
        let updatedProject = try await dataManager.updateProject(project)
        
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = updatedProject
        }
    }
    
    func deleteProject(_ project: Project) async throws {
        let deleted = try await dataManager.deleteProject(project)
        
        if deleted {
            projects.removeAll { $0.id == project.id }
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
        }
    }
    
    // MARK: - 史诗管理
    
    func createEpic(name: String, description: String? = nil) async throws -> Epic {
        let epic = try await dataManager.createEpic(Epic(name: name, description: description ?? ""))
        epics.append(epic)
        return epic
    }
    
    func updateEpic(_ epic: Epic) async throws {
        let updatedEpic = try await dataManager.updateEpic(epic)
        
        if let index = epics.firstIndex(where: { $0.id == epic.id }) {
            epics[index] = updatedEpic
        }
    }
    
    func deleteEpic(_ epic: Epic) async throws {
        let deleted = try await dataManager.deleteEpic(epic)
        
        if deleted {
            epics.removeAll { $0.id == epic.id }
            if selectedEpic?.id == epic.id {
                selectedEpic = nil
            }
        }
    }
    
    // MARK: - 项目统计
    
    func projectProgress(_ project: Project) async -> Double {
        do {
            let projectTasks = try await projectUseCases.getProjectTasks(project.id)
            guard !projectTasks.isEmpty else { return 0 }
            return Double(projectTasks.filter { $0.isCompleted }.count) / Double(projectTasks.count)
        } catch {
            return 0
        }
    }
    
    func epicProgress(_ epic: Epic) async -> Double {
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
    
    func tasksByStatus(in project: Project) async -> [TaskStatus: [XTask]] {
        do {
            let projectTasks = try await projectUseCases.getProjectTasks(project.id)
            return Dictionary(grouping: projectTasks) { $0.status }
        } catch {
            return [:]
        }
    }
    
    func tasksByPriority(in project: Project) async -> [TaskPriority: [XTask]] {
        do {
            let projectTasks = try await projectUseCases.getProjectTasks(project.id)
            return Dictionary(grouping: projectTasks) { $0.priority }
        } catch {
            return [:]
        }
    }
} 
