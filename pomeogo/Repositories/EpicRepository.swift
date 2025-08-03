import Foundation

// MARK: - EpicRepository实现
class EpicRepositoryImpl: EpicRepository {
    private let storage: StorageService
    private let cache: CacheManager
    
    init(storage: StorageService, cache: CacheManager) {
        self.storage = storage
        self.cache = cache
    }
    
    // MARK: - 基本CRUD操作
    
    func create(_ entity: Epic) async throws -> Epic {
        var epic = entity
        epic.updatedAt = Date()
        
        // 保存到存储
        try await storage.save(epic, forKey: "epic_\(epic.id.uuidString)")
        
        // 更新缓存
        await cache.setValue(epic, forKey: "epic_\(epic.id.uuidString)")
        
        return epic
    }
    
    func read(id: UUID) async throws -> Epic? {
        // 先从缓存获取
        if let cachedEpic: Epic = await cache.getValue(forKey: "epic_\(id.uuidString)") {
            return cachedEpic
        }
        
        // 从存储获取
        guard let epic: Epic = try await storage.load(forKey: "epic_\(id.uuidString)") else {
            return nil
        }
        
        // 更新缓存
        await cache.setValue(epic, forKey: "epic_\(id.uuidString)")
        
        return epic
    }
    
    func update(_ entity: Epic) async throws -> Epic {
        var epic = entity
        epic.updatedAt = Date()
        epic.version += 1
        
        // 保存到存储
        try await storage.save(epic, forKey: "epic_\(epic.id.uuidString)")
        
        // 更新缓存
        await cache.setValue(epic, forKey: "epic_\(epic.id.uuidString)")
        
        return epic
    }
    
    func delete(id: UUID) async throws -> Bool {
        // 从存储删除
        let deleted = try await storage.delete(forKey: "epic_\(id.uuidString)")
        
        // 从缓存删除
        await cache.removeValue(forKey: "epic_\(id.uuidString)")
        
        return deleted
    }
    
    func delete(_ entity: Epic) async throws -> Bool {
        return try await delete(id: entity.id)
    }
    
    // MARK: - 批量操作
    
    func readAll() async throws -> [Epic] {
        // 获取所有史诗键
        let keys = try await storage.getAllKeys()
        let epicKeys = keys.filter { $0.hasPrefix("epic_") }
        
        // 批量加载史诗
        var epics: [Epic] = []
        for key in epicKeys {
            if let epic: Epic = try await storage.load(forKey: key) {
                epics.append(epic)
            }
        }
        
        return epics.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func createMany(_ entities: [Epic]) async throws -> [Epic] {
        var createdEpics: [Epic] = []
        
        for entity in entities {
            let createdEpic = try await create(entity)
            createdEpics.append(createdEpic)
        }
        
        return createdEpics
    }
    
    func updateMany(_ entities: [Epic]) async throws -> [Epic] {
        var updatedEpics: [Epic] = []
        
        for entity in entities {
            let updatedEpic = try await update(entity)
            updatedEpics.append(updatedEpic)
        }
        
        return updatedEpics
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
        return keys.filter { $0.hasPrefix("epic_") }.count
    }
    
    func exists(id: UUID) async throws -> Bool {
        return try await storage.exists(forKey: "epic_\(id.uuidString)")
    }
    
    // MARK: - 史诗特定查询
    
    func getActiveEpics() async throws -> [Epic] {
        let allEpics = try await readAll()
        return allEpics.filter { !$0.isArchived }
    }
    
    func getArchivedEpics() async throws -> [Epic] {
        let allEpics = try await readAll()
        return allEpics.filter { $0.isArchived }
    }
    
    func getEpicsByColor(_ color: String) async throws -> [Epic] {
        let allEpics = try await readAll()
        return allEpics.filter { $0.color == color }
    }
    
    // MARK: - 统计查询
    
    func getEpicCountByColor() async throws -> [String: Int] {
        let allEpics = try await readAll()
        var counts: [String: Int] = [:]
        
        for epic in allEpics {
            counts[epic.color, default: 0] += 1
        }
        
        return counts
    }
} 