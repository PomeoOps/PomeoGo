import Foundation

// MARK: - 项目用例
class ProjectUseCases {
    private let projectRepository: any ProjectRepository
    private let taskRepository: any TaskRepository
    private let epicRepository: any EpicRepository
    
    init(projectRepository: any ProjectRepository, taskRepository: any TaskRepository, epicRepository: any EpicRepository) {
        self.projectRepository = projectRepository
        self.taskRepository = taskRepository
        self.epicRepository = epicRepository
    }
    
    // MARK: - 项目创建和更新
    
    func createProject(name: String, description: String? = nil, epicId: UUID? = nil) async throws -> Project {
        let project = Project(
            name: name,
            description: description ?? "",
            epicId: epicId
        )
        
        return try await projectRepository.create(project)
    }
    
    func moveProject(_ projectId: UUID, toEpic epicId: UUID?) async throws -> Project {
        guard let project = try await projectRepository.read(id: projectId) else {
            throw ProjectUseCaseError.projectNotFound(projectId)
        }
        
        if let epicId = epicId {
            guard try await epicRepository.read(id: epicId) != nil else {
                throw ProjectUseCaseError.epicNotFound(epicId)
            }
        }
        
        var updatedProject = project
        updatedProject.epicId = epicId
        
        return try await projectRepository.update(updatedProject)
    }
    
    // MARK: - 项目查询
    
    func getProjectTasks(_ projectId: UUID) async throws -> [XTask] {
        return try await taskRepository.getTasksForProject(projectId)
    }
    
    func getProjectsForEpic(_ epicId: UUID) async throws -> [Project] {
        return try await projectRepository.getProjectsForEpic(epicId)
    }
    
    func getActiveProjects() async throws -> [Project] {
        return try await projectRepository.getActiveProjects()
    }
    
    func getArchivedProjects() async throws -> [Project] {
        return try await projectRepository.getArchivedProjects()
    }
    
    // MARK: - 项目统计
    
    func getProjectStatistics() async throws -> ProjectStatistics {
        let allProjects = try await projectRepository.readAll()
        
        let activeProjects = allProjects.filter { !$0.isArchived }
        let archivedProjects = allProjects.filter { $0.isArchived }
        
        return ProjectStatistics(
            totalProjects: allProjects.count,
            activeProjects: activeProjects.count,
            archivedProjects: archivedProjects.count
        )
    }
}

// MARK: - 项目用例错误
enum ProjectUseCaseError: Error, LocalizedError {
    case projectNotFound(UUID)
    case epicNotFound(UUID)
    case invalidProgressValue
    
    var errorDescription: String? {
        switch self {
        case .projectNotFound(let id):
            return "项目未找到: \(id)"
        case .epicNotFound(let id):
            return "史诗未找到: \(id)"
        case .invalidProgressValue:
            return "进度值无效"
        }
    }
}

// MARK: - 项目统计
struct ProjectStatistics {
    let totalProjects: Int
    let activeProjects: Int
    let archivedProjects: Int
} 