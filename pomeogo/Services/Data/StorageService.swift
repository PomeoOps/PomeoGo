import Foundation

// MARK: - 存储服务协议
protocol StorageService {
    // MARK: - 基本CRUD操作
    
    /// 保存数据
    func save<T: Codable>(_ data: T, forKey key: String) async throws
    
    /// 加载数据
    func load<T: Codable>(forKey key: String) async throws -> T?
    
    /// 删除数据
    func delete(forKey key: String) async throws -> Bool
    
    /// 检查数据是否存在
    func exists(forKey key: String) async throws -> Bool
    
    /// 获取所有键
    func getAllKeys() async throws -> [String]
    
    /// 清空所有数据
    func clear() async throws
    
    // MARK: - 批量操作
    
    /// 批量保存
    func saveBatch<T: Codable>(_ items: [String: T]) async throws
    
    /// 批量加载
    func loadBatch<T: Codable>(forKeys keys: [String]) async throws -> [String: T?]
    
    /// 批量删除
    func deleteBatch(forKeys keys: [String]) async throws -> [String: Bool]
    
    // MARK: - 存储管理
    
    /// 获取可用空间
    func getAvailableSpace() async throws -> Int64
    
    /// 获取存储使用情况
    func getStorageUsage(totalSpace: Int64) async throws -> StorageUsage
    
    /// 备份数据
    func backup() async throws -> Data
    
    /// 恢复数据
    func restore(from backup: Data) async throws
}

// MARK: - 存储错误
enum StorageError: Error, LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    case insufficientSpace
    case backupFailed(String)
    case restoreFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "保存失败: \(message)"
        case .loadFailed(let message):
            return "加载失败: \(message)"
        case .deleteFailed(let message):
            return "删除失败: \(message)"
        case .encodingFailed(let message):
            return "编码失败: \(message)"
        case .decodingFailed(let message):
            return "解码失败: \(message)"
        case .insufficientSpace:
            return "存储空间不足"
        case .backupFailed(let message):
            return "备份失败: \(message)"
        case .restoreFailed(let message):
            return "恢复失败: \(message)"
        case .invalidData:
            return "数据无效"
        }
    }
} 