import Foundation

// MARK: - UserDefaults存储服务实现
class UserDefaultsStorage: StorageService {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        
        // 配置编码器
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        // 配置解码器
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - 基本存储操作
    
    func save<T: Codable>(_ data: T, forKey key: String) async throws {
        do {
            let data = try encoder.encode(data)
            userDefaults.set(data, forKey: key)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    func load<T: Codable>(forKey key: String) async throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
    
    func delete(forKey key: String) async throws -> Bool {
        userDefaults.removeObject(forKey: key)
        return true
    }
    
    func exists(forKey key: String) async throws -> Bool {
        return userDefaults.object(forKey: key) != nil
    }
    
    // MARK: - 批量操作
    
    func getAllKeys() async throws -> [String] {
        return Array(userDefaults.dictionaryRepresentation().keys)
    }
    
    func getAllKeys(prefix: String) async throws -> [String] {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        return allKeys.filter { $0.hasPrefix(prefix) }
    }
    
    func deleteAll(prefix: String) async throws -> Bool {
        let keys = try await getAllKeys(prefix: prefix)
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
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
        let domain = Bundle.main.bundleIdentifier ?? "com.pomeogo"
        userDefaults.removePersistentDomain(forName: domain)
    }
    
    func getAvailableSpace() async throws -> Int64 {
        // UserDefaults没有空间限制，返回一个很大的值
        return Int64.max
    }
    
    func getStorageUsage(totalSpace: Int64) async throws -> StorageUsage {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        var totalSize: Int64 = 0
        
        for key in allKeys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += Int64(data.count)
            }
        }
        
        return StorageUsage(
            userDefaultsSize: totalSize,
            fileSystemSize: 0,
            cacheSize: 0,
            totalSize: totalSize
        )
    }
    
    func getStorageSize() async throws -> Int64 {
        let allKeys = userDefaults.dictionaryRepresentation().keys
        var totalSize: Int64 = 0
        
        for key in allKeys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += Int64(data.count)
            }
        }
        
        return totalSize
    }
    
    func backup() async throws -> Data {
        let allData = userDefaults.dictionaryRepresentation()
        
        do {
            return try NSKeyedArchiver.archivedData(withRootObject: allData, requiringSecureCoding: false)
        } catch {
            throw StorageError.encodingFailed(error.localizedDescription)
        }
    }
    
    func restore(from backup: Data) async throws {
        do {
            guard let allData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(backup) as? [String: Any] else {
                throw StorageError.decodingFailed("无法解码备份数据")
            }
            
            // 清除现有数据
            try await clear()
            
            // 恢复数据
            for (key, value) in allData {
                userDefaults.set(value, forKey: key)
            }
        } catch {
            throw StorageError.decodingFailed(error.localizedDescription)
        }
    }
}

 