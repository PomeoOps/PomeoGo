import Foundation

// MARK: - 文件系统存储服务实现
class FileSystemStorage: StorageService {
    private let documentsDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager
    
    init(documentsDirectory: URL? = nil) throws {
        self.fileManager = FileManager.default
        
        if let documentsDirectory = documentsDirectory {
            self.documentsDirectory = documentsDirectory
        } else {
            self.documentsDirectory = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("PomeoGo_FileStorage")
        }
        
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        
        // 配置编码器
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        // 配置解码器
        decoder.dateDecodingStrategy = .iso8601
        
        // 创建存储目录
        try createStorageDirectoryIfNeeded()
    }
    
    // MARK: - 基本存储操作
    
    func save<T: Codable>(_ data: T, forKey key: String) async throws {
        let fileURL = documentsDirectory.appendingPathComponent("\(key).json")
        
        do {
            let data = try encoder.encode(data)
            try data.write(to: fileURL)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    func load<T: Codable>(forKey key: String) async throws -> T? {
        let fileURL = documentsDirectory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    func delete(forKey key: String) async throws -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent("\(key).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return false
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            throw StorageError.deleteFailed("权限被拒绝")
        }
    }
    
    func exists(forKey key: String) async throws -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent("\(key).json")
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    // MARK: - 批量操作
    
    func getAllKeys() async throws -> [String] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )
            
            return fileURLs.map { $0.lastPathComponent.replacingOccurrences(of: ".json", with: "") }
        } catch {
            throw StorageError.loadFailed("获取文件列表失败")
        }
    }
    
    func getAllKeys(prefix: String) async throws -> [String] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.nameKey],
                options: [.skipsHiddenFiles]
            )
            
            return fileURLs
                .filter { $0.lastPathComponent.hasPrefix(prefix) }
                .map { $0.lastPathComponent.replacingOccurrences(of: ".json", with: "") }
        } catch {
            throw StorageError.loadFailed("获取文件列表失败")
        }
    }
    
    func deleteAll(prefix: String) async throws -> Bool {
        let keys = try await getAllKeys(prefix: prefix)
        
        for key in keys {
            try await delete(forKey: key)
        }
        
        return true
    }
    
    func saveBatch<T: Codable>(_ items: [String: T]) async throws {
        for (key, item) in items {
            try await save(item, forKey: key)
        }
    }
    
    func loadBatch<T: Codable>(forKeys keys: [String]) async throws -> [String: T?] {
        var results: [String: T?] = [:]
        
        for key in keys {
            results[key] = try await load(forKey: key)
        }
        
        return results
    }
    
    func deleteBatch(forKeys keys: [String]) async throws -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        for key in keys {
            results[key] = try await delete(forKey: key)
        }
        
        return results
    }
    
    func saveMany<T: Codable>(entities: [T], forKeys keys: [String]) async throws {
        guard entities.count == keys.count else {
            throw StorageError.invalidData
        }
        
        for (index, entity) in entities.enumerated() {
            try await save(entity, forKey: keys[index])
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
    
    // MARK: - 数据管理
    
    func clear() async throws {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            throw StorageError.deleteFailed("清除文件失败")
        }
    }
    
    func getAvailableSpace() async throws -> Int64 {
        do {
            let resourceValues = try documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(resourceValues.volumeAvailableCapacity ?? 0)
        } catch {
            throw StorageError.loadFailed("获取可用空间失败")
        }
    }
    
    func getStorageUsage(totalSpace: Int64) async throws -> StorageUsage {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var totalSize: Int64 = 0
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            let availableSpace = try await getAvailableSpace()
            
            return StorageUsage(
                userDefaultsSize: 0,
                fileSystemSize: totalSize,
                cacheSize: 0,
                totalSize: totalSize
            )
        } catch {
            throw StorageError.loadFailed("获取存储使用情况失败")
        }
    }
    
    func getStorageSize() async throws -> Int64 {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            
            var totalSize: Int64 = 0
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
            
            return totalSize
        } catch {
            throw StorageError.loadFailed("获取存储大小失败")
        }
    }
    
    func backup() async throws -> Data {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: documentsDirectory,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            var backupData: [String: Data] = [:]
            
            for fileURL in fileURLs {
                let key = fileURL.lastPathComponent.replacingOccurrences(of: ".json", with: "")
                let data = try Data(contentsOf: fileURL)
                backupData[key] = data
            }
            
            return try JSONEncoder().encode(backupData)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    func restore(from backup: Data) async throws {
        do {
            // 清除现有数据
            try await clear()
            
            // 恢复数据
            let backupData = try JSONDecoder().decode([String: Data].self, from: backup)
            
            for (key, fileData) in backupData {
                let fileURL = documentsDirectory.appendingPathComponent("\(key).json")
                try fileData.write(to: fileURL)
            }
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - 私有辅助方法
    
    private func createStorageDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
} 