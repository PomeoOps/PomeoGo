import Foundation

// MARK: - 简化数据仓储协议
protocol SimpleDataRepository {
    associatedtype Entity: Identifiable & Codable
    
    // 基本CRUD操作
    func create(_ entity: Entity) async throws -> Entity
    func read(id: Entity.ID) async throws -> Entity?
    func update(_ entity: Entity) async throws -> Entity
    func delete(id: Entity.ID) async throws -> Bool
    func delete(_ entity: Entity) async throws -> Bool
    
    // 批量操作
    func readAll() async throws -> [Entity]
    func createMany(_ entities: [Entity]) async throws -> [Entity]
    func updateMany(_ entities: [Entity]) async throws -> [Entity]
    func deleteMany(ids: [Entity.ID]) async throws -> Bool
    
    // 查询操作
    func count() async throws -> Int
    func exists(id: Entity.ID) async throws -> Bool
}

// MARK: - 简化存储服务协议
protocol SimpleStorageService {
    // 基本存储操作
    func save<T: Codable>(_ data: T, forKey key: String) async throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) async throws -> T?
    func delete(forKey key: String) async throws
    func exists(forKey key: String) async throws -> Bool
    
    // 批量操作
    func saveMany<T: Codable>(_ data: [T], forKey key: String) async throws
    func loadMany<T: Codable>(_ type: T.Type, forKey key: String) async throws -> [T]
    func deleteMany(forKeys keys: [String]) async throws
    
    // 存储管理
    func clear() async throws
    func getStorageSize() async throws -> Int64
    func getAvailableSpace() async throws -> Int64
}

// MARK: - 简化错误类型
enum SimpleRepositoryError: Error, LocalizedError {
    case entityNotFound
    case entityAlreadyExists
    case invalidEntity
    case storageError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .entityNotFound:
            return "实体未找到"
        case .entityAlreadyExists:
            return "实体已存在"
        case .invalidEntity:
            return "无效的实体数据"
        case .storageError(let message):
            return "存储错误: \(message)"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
} 