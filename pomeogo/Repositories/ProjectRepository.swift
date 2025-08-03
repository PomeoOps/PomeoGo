import Foundation

// MARK: - ProjectRepository实现
class ProjectRepositoryImpl: ProjectRepository {
    private let storage: StorageService
    private let cache: CacheManager
    
    init(storage: StorageService, cache: CacheManager) {
        self.storage = storage
        self.cache = cache
    }
    
    // MARK: - 基本CRUD操作
    
    func create(_ entity: Project) async throws -> Project {
        var project = entity
        project.updatedAt = Date()
        
        // 保存到存储
        try await storage.save(project, forKey: "project_\(project.id.uuidString)")
        
        // 更新缓存
        await cache.setValue(project, forKey: "project_\(project.id.uuidString)")
        
        return project
    }
    
    func read(id: UUID) async throws -> Project? {
        // 先从缓存获取
        if let cachedProject: Project = await cache.getValue(forKey: "project_\(id.uuidString)") {
            return cachedProject
        }
        
        // 从存储获取
        guard let project: Project = try await storage.load(forKey: "project_\(id.uuidString)") else {
            return nil
        }
        
        // 更新缓存
        await cache.setValue(project, forKey: "project_\(id.uuidString)")
        
        return project
    }
    
    func update(_ entity: Project) async throws -> Project {
        var project = entity
        project.updatedAt = Date()
        project.version += 1
        
        // 保存到存储
        try await storage.save(project, forKey: "project_\(project.id.uuidString)")
        
        // 更新缓存
        await cache.setValue(project, forKey: "project_\(project.id.uuidString)")
        
        return project
    }
    
    func delete(id: UUID) async throws -> Bool {
        // 从存储删除
        let deleted = try await storage.delete(forKey: "project_\(id.uuidString)")
        
        // 从缓存删除
        await cache.removeValue(forKey: "project_\(id.uuidString)")
        
        return deleted
    }
    
    func delete(_ entity: Project) async throws -> Bool {
        return try await delete(id: entity.id)
    }
    
    // MARK: - 批量操作
    
    func readAll() async throws -> [Project] {
        // 获取所有项目键
        let allKeys = try await storage.getAllKeys()
        let keys = allKeys.filter { $0.hasPrefix("project_") }
        
        // 批量加载项目
        var projects: [Project] = []
        for key in keys {
            if let project: Project = try await storage.load(forKey: key) {
                projects.append(project)
            }
        }
        
        return projects.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func createMany(_ entities: [Project]) async throws -> [Project] {
        var createdProjects: [Project] = []
        
        for entity in entities {
            let createdProject = try await create(entity)
            createdProjects.append(createdProject)
        }
        
        return createdProjects
    }
    
    func updateMany(_ entities: [Project]) async throws -> [Project] {
        var updatedProjects: [Project] = []
        
        for entity in entities {
            let updatedProject = try await update(entity)
            updatedProjects.append(updatedProject)
        }
        
        return updatedProjects
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
        let keys = try await storage.getAllKeys()
        return keys.filter { $0.hasPrefix("project_") }.count
    }
    
    func exists(id: UUID) async throws -> Bool {
        return try await storage.exists(forKey: "project_\(id.uuidString)")
    }
    
    // MARK: - 项目特定查询
    
    func getActiveProjects() async throws -> [Project] {
        let allProjects = try await readAll()
        return allProjects.filter { !$0.isArchived }
    }
    
    func getArchivedProjects() async throws -> [Project] {
        let allProjects = try await readAll()
        return allProjects.filter { $0.isArchived }
    }
    
    func getProjectsForEpic(_ epicId: UUID) async throws -> [Project] {
        let allProjects = try await readAll()
        return allProjects.filter { $0.epicId == epicId }
    }
    
    func getProjectsByColor(_ color: String) async throws -> [Project] {
        let allProjects = try await readAll()
        return allProjects.filter { $0.color == color }
    }
    
    // MARK: - 统计查询
    
    func getProjectCountByEpic() async throws -> [UUID: Int] {
        let allProjects = try await readAll()
        var counts: [UUID: Int] = [:]
        
        for project in allProjects {
            if let epicId = project.epicId {
                counts[epicId, default: 0] += 1
            }
        }
        
        return counts
    }
    
    func getProjectCountByColor() async throws -> [String: Int] {
        let allProjects = try await readAll()
        var counts: [String: Int] = [:]
        
        for project in allProjects {
            counts[project.color, default: 0] += 1
        }
        
        return counts
    }
} 