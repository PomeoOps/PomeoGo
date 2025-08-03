import Foundation

// MARK: - 存储管理器
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    // 存储服务
    private let userDefaultsStorage: UserDefaultsStorage
    private let fileSystemStorage: FileSystemStorage
    private let cacheManager: CacheManager
    
    // 存储策略
    private var storageStrategy: StorageStrategy = .hybrid
    
    // 配置
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxUserDefaultsSize: Int64 = 10 * 1024 * 1024 // 10MB
    
    // 监控
    @Published var storageUsage: StorageUsage = StorageUsage()
    @Published var isStorageOptimized: Bool = true
    
    private init() {
        self.userDefaultsStorage = UserDefaultsStorage()
        self.fileSystemStorage = try! FileSystemStorage()
        self.cacheManager = CacheManager()
        
        // 启动存储监控
        _Concurrency.Task {
            await startStorageMonitoring()
        }
    }
    
    // MARK: - 存储策略管理
    
    func setStorageStrategy(_ strategy: StorageStrategy) {
        self.storageStrategy = strategy
        _Concurrency.Task {
            await optimizeStorage()
        }
    }
    
    func getStorageStrategy() -> StorageStrategy {
        return storageStrategy
    }
    
    // MARK: - 智能存储操作
    
    func save<T: Codable>(entity: T, forKey key: String, priority: StoragePriority = .normal) async throws {
        switch storageStrategy {
        case .userDefaults:
            try await userDefaultsStorage.save(entity, forKey: key)
            
        case .fileSystem:
            try await fileSystemStorage.save(entity, forKey: key)
            
        case .hybrid:
            // 根据优先级和大小决定存储位置
            let data = try JSONEncoder().encode(entity)
            let size = Int64(data.count)
            
            if priority == .high || size <= 1024 { // 1KB以下或高优先级使用UserDefaults
                try await userDefaultsStorage.save(entity, forKey: key)
            } else {
                try await fileSystemStorage.save(entity, forKey: key)
            }
        }
        
        // 更新缓存
        await cacheManager.setValue(entity, forKey: key)
        
        // 更新使用情况
        await updateStorageUsage(totalSpace: Int64.max)
    }
    
    func load<T: Codable>(forKey key: String) async throws -> T? {
        // 先从缓存获取
        if let cachedValue: T = await cacheManager.getValue(forKey: key) {
            return cachedValue
        }
        
        // 根据策略从相应存储加载
        var value: T?
        
        switch storageStrategy {
        case .userDefaults:
            value = try await userDefaultsStorage.load(forKey: key)
            
        case .fileSystem:
            value = try await fileSystemStorage.load(forKey: key)
            
        case .hybrid:
            // 尝试从UserDefaults加载，如果失败则从文件系统加载
            value = try await userDefaultsStorage.load(forKey: key)
            if value == nil {
                value = try await fileSystemStorage.load(forKey: key)
            }
        }
        
        // 更新缓存
        if let value = value {
            await cacheManager.setValue(value, forKey: key)
        }
        
        return value
    }
    
    func delete(forKey key: String) async throws -> Bool {
        var deleted = false
        
        // 从所有存储中删除
        let userDefaultsDeleted = try await userDefaultsStorage.delete(forKey: key)
        let fileSystemDeleted = try await fileSystemStorage.delete(forKey: key)
        
        deleted = userDefaultsDeleted || fileSystemDeleted
        
        // 从缓存删除
        await cacheManager.removeValue(forKey: key)
        
        // 更新使用情况
        await updateStorageUsage(totalSpace: Int64.max)
        
        return deleted
    }
    
    func exists(forKey key: String) async throws -> Bool {
        // 检查缓存
        if await cacheManager.exists(forKey: key) {
            return true
        }
        
        // 根据策略检查存储
        switch storageStrategy {
        case .userDefaults:
            return try await userDefaultsStorage.exists(forKey: key)
            
        case .fileSystem:
            return try await fileSystemStorage.exists(forKey: key)
            
        case .hybrid:
            let userDefaultsExists = try await userDefaultsStorage.exists(forKey: key)
            let fileSystemExists = try await fileSystemStorage.exists(forKey: key)
            return userDefaultsExists || fileSystemExists
        }
    }
    
    // MARK: - 批量操作
    
    func saveMany<T: Codable>(entities: [T], forKeys keys: [String], priority: StoragePriority = .normal) async throws {
        guard entities.count == keys.count else {
            throw StorageError.invalidData
        }
        
        for (index, entity) in entities.enumerated() {
            try await save(entity: entity, forKey: keys[index], priority: priority)
        }
    }
    
    func loadMany<T: Codable>(forKeys keys: [String]) async throws -> [T?] {
        var results: [T?] = []
        
        for key in keys {
            let result: T? = try await load(forKey: key)
            results.append(result)
        }
        
        return results
    }
    
    func deleteMany(forKeys keys: [String]) async throws -> Bool {
        var allDeleted = true
        
        for key in keys {
            let deleted = try await delete(forKey: key)
            if !deleted {
                allDeleted = false
            }
        }
        
        return allDeleted
    }
    
    // MARK: - 存储优化
    
    private func optimizeStorage() async {
        // 检查UserDefaults大小
        let userDefaultsSize = try? await userDefaultsStorage.getStorageSize()
        if let size = userDefaultsSize, size > maxUserDefaultsSize {
            await migrateToFileSystem()
        }
        
        // 清理缓存
        await cacheManager.cleanup()
        
        // 更新使用情况
        await updateStorageUsage(totalSpace: Int64.max)
        
        // 更新优化状态
        await MainActor.run {
            self.isStorageOptimized = true
        }
    }
    
    private func migrateToFileSystem() async {
        // 获取所有UserDefaults键
        let keys = try? await userDefaultsStorage.getAllKeys(prefix: "")
        
        guard let keys = keys else { return }
        
        for key in keys {
            // 尝试加载数据
            if let data: Data = try? await userDefaultsStorage.load(forKey: key) {
                // 保存到文件系统
                try? await fileSystemStorage.save(data, forKey: key)
                // 从UserDefaults删除
                try? await userDefaultsStorage.delete(forKey: key)
            }
        }
    }
    
    // MARK: - 存储监控
    
    private func startStorageMonitoring() async {
        while true {
            await updateStorageUsage(totalSpace: Int64.max)
            
            // 检查是否需要优化
            if !isStorageOptimized {
                await optimizeStorage()
            }
            
            // 每5分钟检查一次
            try? await _Concurrency.Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
        }
    }
    
    private func updateStorageUsage(totalSpace: Int64) async {
        let userDefaultsSize = (try? await userDefaultsStorage.getStorageSize()) ?? 0
        let fileSystemSize = (try? await fileSystemStorage.getStorageSize()) ?? 0
        let cacheSize = await cacheManager.getCacheSize()
        
        let totalSize = userDefaultsSize + fileSystemSize + cacheSize
        
        await MainActor.run {
            self.storageUsage = StorageUsage(
                userDefaultsSize: userDefaultsSize,
                fileSystemSize: fileSystemSize,
                cacheSize: cacheSize,
                totalSize: totalSize
            )
            
            // 检查是否需要优化
            self.isStorageOptimized = totalSize < maxCacheSize && userDefaultsSize < maxUserDefaultsSize
        }
    }
    
    // MARK: - 数据管理
    
    func clearAllData() async throws -> Bool {
        try await userDefaultsStorage.clear()
        try await fileSystemStorage.clear()
        await cacheManager.clear()
        
        await updateStorageUsage(totalSpace: Int64.max)
        
        return true
    }
    
    func backupData() async throws -> Data {
        // 创建包含所有存储的备份
        let userDefaultsBackup = try await userDefaultsStorage.backup()
        let fileSystemBackup = try await fileSystemStorage.backup()
        
        let backup = StorageBackup(
            userDefaultsData: userDefaultsBackup,
            fileSystemData: fileSystemBackup,
            timestamp: Date()
        )
        
        return try JSONEncoder().encode(backup)
    }
    
    func restoreData(from data: Data) async throws -> Bool {
        let backup = try JSONDecoder().decode(StorageBackup.self, from: data)
        
        try await userDefaultsStorage.restore(from: backup.userDefaultsData)
        try await fileSystemStorage.restore(from: backup.fileSystemData)
        
        await updateStorageUsage(totalSpace: Int64.max)
        
        return true
    }
    
    func getStorageInfo() async -> StorageInfo {
        let userDefaultsSize = (try? await userDefaultsStorage.getStorageSize()) ?? 0
        let fileSystemSize = (try? await fileSystemStorage.getStorageSize()) ?? 0
        let cacheSize = await cacheManager.getCacheSize()
        
        return StorageInfo(
            strategy: storageStrategy,
            userDefaultsSize: userDefaultsSize,
            fileSystemSize: fileSystemSize,
            cacheSize: cacheSize,
            isOptimized: isStorageOptimized
        )
    }
}

// MARK: - 存储策略
enum StorageStrategy {
    case userDefaults
    case fileSystem
    case hybrid
}

// MARK: - 存储优先级
enum StoragePriority {
    case low
    case normal
    case high
}

// MARK: - 存储使用情况
struct StorageUsage {
    let userDefaultsSize: Int64
    let fileSystemSize: Int64
    let cacheSize: Int64
    let totalSize: Int64
    
    init(userDefaultsSize: Int64 = 0, fileSystemSize: Int64 = 0, cacheSize: Int64 = 0, totalSize: Int64 = 0) {
        self.userDefaultsSize = userDefaultsSize
        self.fileSystemSize = fileSystemSize
        self.cacheSize = cacheSize
        self.totalSize = totalSize
    }
}

// MARK: - 存储信息
struct StorageInfo {
    let strategy: StorageStrategy
    let userDefaultsSize: Int64
    let fileSystemSize: Int64
    let cacheSize: Int64
    let isOptimized: Bool
}

// MARK: - 存储备份
struct StorageBackup: Codable {
    let userDefaultsData: Data
    let fileSystemData: Data
    let timestamp: Date
} 