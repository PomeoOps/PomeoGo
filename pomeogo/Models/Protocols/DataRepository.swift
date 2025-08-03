import Foundation

// MARK: - 数据仓储协议
protocol DataRepository {
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

// MARK: - 任务仓储协议
protocol TaskRepository: DataRepository where Entity == XTask {
    // 任务特定查询
    func getTasksForProject(_ projectId: UUID) async throws -> [XTask]
    func getTasksForEpic(_ epicId: UUID) async throws -> [XTask]
    func getTasksWithTag(_ tagId: UUID) async throws -> [XTask]
    func getCompletedTasks() async throws -> [XTask]
    func getPendingTasks() async throws -> [XTask]
    func getOverdueTasks() async throws -> [XTask]
    func getTasksByStatus(_ status: TaskStatus) async throws -> [XTask]
    func getTasksByPriority(_ priority: TaskPriority) async throws -> [XTask]
    func getTasksByAssignee(_ assignee: String) async throws -> [XTask]
    func getTasksWithDependencies() async throws -> [XTask]
    func getTasksDueBetween(_ startDate: Date, _ endDate: Date) async throws -> [XTask]
    
    // 统计查询
    func getTaskCountByStatus() async throws -> [TaskStatus: Int]
    func getTaskCountByPriority() async throws -> [TaskPriority: Int]
    func getTaskCountByProject() async throws -> [UUID: Int]
    func getTaskCountByEpic() async throws -> [UUID: Int]
}

// MARK: - 项目仓储协议
protocol ProjectRepository: DataRepository where Entity == Project {
    // 项目特定查询
    func getActiveProjects() async throws -> [Project]
    func getArchivedProjects() async throws -> [Project]
    func getProjectsForEpic(_ epicId: UUID) async throws -> [Project]
    func getProjectsByColor(_ color: String) async throws -> [Project]
    
    // 统计查询
    func getProjectCountByEpic() async throws -> [UUID: Int]
    func getProjectCountByColor() async throws -> [String: Int]
}

// MARK: - 史诗仓储协议
protocol EpicRepository: DataRepository where Entity == Epic {
    // 史诗特定查询
    func getActiveEpics() async throws -> [Epic]
    func getArchivedEpics() async throws -> [Epic]
    func getEpicsByColor(_ color: String) async throws -> [Epic]
    
    // 统计查询
    func getEpicCountByColor() async throws -> [String: Int]
}

// MARK: - 标签仓储协议
protocol TagRepository: DataRepository where Entity == Tag {
    // 标签特定查询
    func getTagsByColor(_ color: String) async throws -> [Tag]
    func getTagsByName(_ name: String) async throws -> [Tag]
    
    // 统计查询
    func getTagCountByColor() async throws -> [String: Int]
}

// MARK: - 附件仓储协议
protocol AttachmentRepository: DataRepository where Entity == Attachment {
    // 附件特定查询
    func getAttachmentsByType(_ type: AttachmentType) async throws -> [Attachment]
    func getAttachmentsBySizeRange(min: Int64, max: Int64) async throws -> [Attachment]
    func getAttachmentsCreatedAfter(_ date: Date) async throws -> [Attachment]
    
    // 文件操作
    func saveFile(_ data: Data, fileName: String) async throws -> Attachment
    func deleteFile(_ attachment: Attachment) async throws -> Bool
    func getFileData(_ attachment: Attachment) async throws -> Data
    
    // 统计查询
    func getAttachmentCountByType() async throws -> [AttachmentType: Int]
    func getTotalStorageUsed() async throws -> Int64
}

// MARK: - 清单项仓储协议
protocol ChecklistItemRepository: DataRepository where Entity == ChecklistItem {
    // 清单项特定查询
    func getCompletedItems() async throws -> [ChecklistItem]
    func getPendingItems() async throws -> [ChecklistItem]
    func getItemsByTitle(_ title: String) async throws -> [ChecklistItem]
    
    // 统计查询
    func getCompletionRate() async throws -> Double
    func getItemCountByStatus() async throws -> [Bool: Int]
}

// MARK: - 错误类型
enum RepositoryError: Error, LocalizedError {
    case entityNotFound
    case entityAlreadyExists
    case invalidEntity
    case storageError(String)
    case networkError(String)
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
        case .networkError(let message):
            return "网络错误: \(message)"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
} 