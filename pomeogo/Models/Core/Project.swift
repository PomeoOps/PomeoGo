import Foundation

// 核心项目模型，移除SwiftData依赖
struct Project: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var color: String
    var epicId: UUID?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 版本控制
    var version: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        color: String = "blue",
        epicId: UUID? = nil,
        isArchived: Bool = false,
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.epicId = epicId
        self.isArchived = isArchived
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = version
    }
    
    // MARK: - 业务方法
    mutating func updateName(_ newName: String) {
        name = newName
        updatedAt = Date()
        version += 1
    }
    
    mutating func updateDescription(_ newDescription: String) {
        description = newDescription
        updatedAt = Date()
        version += 1
    }
    
    mutating func updateColor(_ newColor: String) {
        color = newColor
        updatedAt = Date()
        version += 1
    }
    
    mutating func assignToEpic(_ epicId: UUID?) {
        self.epicId = epicId
        updatedAt = Date()
        version += 1
    }
    
    mutating func archive() {
        isArchived = true
        updatedAt = Date()
        version += 1
    }
    
    mutating func unarchive() {
        isArchived = false
        updatedAt = Date()
        version += 1
    }
    
    // MARK: - 计算属性
    var isActive: Bool {
        return !isArchived
    }
    
    var displayName: String {
        return name.isEmpty ? "未命名项目" : name
    }
    
    var shortDescription: String {
        return description.isEmpty ? "暂无描述" : description
    }
}

// MARK: - 项目颜色选项
extension Project {
    static let availableColors = [
        "red", "orange", "yellow", "green", 
        "blue", "purple", "pink", "gray", 
        "brown", "cyan", "mint", "indigo"
    ]
    
    static func randomColor() -> String {
        return availableColors.randomElement() ?? "blue"
    }
} 