import Foundation

// 核心标签模型，移除SwiftData依赖
struct Tag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var color: String
    var createdAt: Date
    var updatedAt: Date
    
    // 版本控制
    var version: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        color: String = "gray",
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.color = color
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
    
    mutating func updateColor(_ newColor: String) {
        color = newColor
        updatedAt = Date()
        version += 1
    }
    
    // MARK: - 计算属性
    var displayName: String {
        return name.isEmpty ? "未命名标签" : name
    }
}

// MARK: - 标签颜色选项
extension Tag {
    static let availableColors = [
        "red", "orange", "yellow", "green", 
        "blue", "purple", "pink", "gray", 
        "brown", "cyan", "mint", "indigo"
    ]
    
    static func randomColor() -> String {
        return availableColors.randomElement() ?? "gray"
    }
} 