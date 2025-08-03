import Foundation

// 核心清单项模型，移除SwiftData依赖
struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    // 版本控制
    var version: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        version: Int = 1
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = version
    }
    
    // MARK: - 业务方法
    mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        updatedAt = Date()
        version += 1
    }
    
    mutating func toggleCompletion() {
        isCompleted.toggle()
        updatedAt = Date()
        completedAt = isCompleted ? Date() : nil
        version += 1
    }
    
    mutating func markCompleted() {
        if !isCompleted {
            isCompleted = true
            completedAt = Date()
            updatedAt = Date()
            version += 1
        }
    }
    
    mutating func markIncomplete() {
        if isCompleted {
            isCompleted = false
            completedAt = nil
            updatedAt = Date()
            version += 1
        }
    }
    
    // MARK: - 计算属性
    var displayTitle: String {
        return title.isEmpty ? "未命名项目" : title
    }
    
    var isOverdue: Bool {
        // 可以根据需要添加截止日期逻辑
        return false
    }
} 