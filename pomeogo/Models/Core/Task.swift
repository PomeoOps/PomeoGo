import Foundation

// 核心任务模型，移除SwiftData依赖
struct XTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var startDate: Date?
    var endDate: Date?
    var priority: TaskPriority
    var status: TaskStatus
    var reminderDate: Date?
    
    // 位置提醒
    var locationEnabled: Bool
    var locationLat: Double?
    var locationLng: Double?
    var locationAddress: String?
    
    // 重复提醒
    var repeatEnabled: Bool
    var repeatType: RepeatType
    var repeatInterval: Int
    var repeatEndDate: Date?
    
    // 关联关系（使用ID引用避免循环依赖）
    var parentId: UUID?
    var projectId: UUID?
    var epicId: UUID?
    var tagIds: [UUID]
    var dependencyIds: [UUID]
    
    var notes: String?
    var checklistItemIds: [UUID] // 使用ID引用替代直接类型
    var attachmentIds: [UUID] // 使用ID引用替代直接类型
    var isCompleted: Bool
    var dueDate: Date?
    var estimatedHours: Double?
    var actualHours: Double?
    var assignee: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    // 版本控制
    var version: Int
    
    init(
        id: UUID = UUID(),
        title: String,
        startDate: Date? = nil,
        endDate: Date? = nil,
        priority: TaskPriority = .normal,
        status: TaskStatus = .todo,
        reminderDate: Date? = nil,
        locationEnabled: Bool = false,
        locationLat: Double? = nil,
        locationLng: Double? = nil,
        locationAddress: String? = nil,
        repeatEnabled: Bool = false,
        repeatType: RepeatType = .none,
        repeatInterval: Int = 1,
        repeatEndDate: Date? = nil,
        parentId: UUID? = nil,
        projectId: UUID? = nil,
        epicId: UUID? = nil,
        tagIds: [UUID] = [],
        dependencyIds: [UUID] = [],
        notes: String? = nil,
        checklistItemIds: [UUID] = [],
        attachmentIds: [UUID] = [],
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        estimatedHours: Double? = nil,
        actualHours: Double? = nil,
        assignee: String? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.priority = priority
        self.status = status
        self.reminderDate = reminderDate
        self.locationEnabled = locationEnabled
        self.locationLat = locationLat
        self.locationLng = locationLng
        self.locationAddress = locationAddress
        self.repeatEnabled = repeatEnabled
        self.repeatType = repeatType
        self.repeatInterval = repeatInterval
        self.repeatEndDate = repeatEndDate
        self.parentId = parentId
        self.projectId = projectId
        self.epicId = epicId
        self.tagIds = tagIds
        self.dependencyIds = dependencyIds
        self.notes = notes
        self.checklistItemIds = checklistItemIds
        self.attachmentIds = attachmentIds
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.estimatedHours = estimatedHours
        self.actualHours = actualHours
        self.assignee = assignee
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = version
    }
    
    // MARK: - 业务方法
    mutating func markCompleted() {
        isCompleted = true
        completedAt = Date()
        updatedAt = Date()
        version += 1
    }
    
    mutating func toggleCompleted() {
        isCompleted.toggle()
        if isCompleted {
            completedAt = Date()
        } else {
            completedAt = nil
        }
        updatedAt = Date()
        version += 1
    }
    
    mutating func updateStatus(_ newStatus: TaskStatus) {
        status = newStatus
        updatedAt = Date()
        version += 1
    }
    
    mutating func updatePriority(_ newPriority: TaskPriority) {
        priority = newPriority
        updatedAt = Date()
        version += 1
    }
    
    mutating func addTag(_ tagId: UUID) {
        if !tagIds.contains(tagId) {
            tagIds.append(tagId)
            updatedAt = Date()
            version += 1
        }
    }
    
    mutating func removeTag(_ tagId: UUID) {
        tagIds.removeAll { $0 == tagId }
        updatedAt = Date()
        version += 1
    }
    
    mutating func addDependency(_ taskId: UUID) {
        if !dependencyIds.contains(taskId) && taskId != id {
            dependencyIds.append(taskId)
            updatedAt = Date()
            version += 1
        }
    }
    
    mutating func removeDependency(_ taskId: UUID) {
        dependencyIds.removeAll { $0 == taskId }
        updatedAt = Date()
        version += 1
    }
    
    mutating func addChecklistItem(_ itemId: UUID) {
        if !checklistItemIds.contains(itemId) {
            checklistItemIds.append(itemId)
            updatedAt = Date()
            version += 1
        }
    }
    
    mutating func removeChecklistItem(_ itemId: UUID) {
        checklistItemIds.removeAll { $0 == itemId }
        updatedAt = Date()
        version += 1
    }
    
    mutating func addAttachment(_ attachmentId: UUID) {
        if !attachmentIds.contains(attachmentId) {
            attachmentIds.append(attachmentId)
            updatedAt = Date()
            version += 1
        }
    }
    
    mutating func removeAttachment(_ attachmentId: UUID) {
        attachmentIds.removeAll { $0 == attachmentId }
        updatedAt = Date()
        version += 1
    }
    
    // MARK: - 计算属性
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    var timeSpent: TimeInterval {
        guard let start = startDate else { return 0 }
        let end = endDate ?? Date()
        return end.timeIntervalSince(start)
    }
}

// MARK: - 枚举定义
enum TaskPriority: Int, Codable, CaseIterable, Hashable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
    
    var title: String {
        switch self {
        case .low: return "低"
        case .normal: return "普通"
        case .high: return "高"
        case .urgent: return "紧急"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "green"
        case .normal: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle"
        case .normal: return "circle"
        case .high: return "arrow.up.circle"
        case .urgent: return "exclamationmark.triangle"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case todo = "待处理"
    case inProgress = "进行中"
    case blocked = "已阻塞"
    case review = "待审核"
    case completed = "已完成"
    
    var color: String {
        switch self {
        case .todo: return "gray"
        case .inProgress: return "blue"
        case .blocked: return "red"
        case .review: return "orange"
        case .completed: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "arrow.clockwise"
        case .blocked: return "exclamationmark.triangle"
        case .review: return "eye"
        case .completed: return "checkmark.circle"
        }
    }
}

enum RepeatType: String, Codable, CaseIterable {
    case none = "none"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
    
    var title: String {
        switch self {
        case .none: return "不重复"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
} 