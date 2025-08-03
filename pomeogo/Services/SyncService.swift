import Foundation
import CloudKit

class SyncService {
    private let cloudKitHelper: CloudKitHelper
    private let dataManager: DataManager
    private let container: CKContainer
    private let database: CKDatabase
    
    init(cloudKitHelper: CloudKitHelper, dataManager: DataManager) {
        self.cloudKitHelper = cloudKitHelper
        self.dataManager = dataManager
        self.container = CKContainer.default()
        self.database = container.privateCloudDatabase
        
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDatabaseChanges),
            name: NSNotification.Name.CKAccountChanged,
            object: nil
        )
    }
    
    // MARK: - 同步管理
    
    func startSync() async throws {
        try await syncTasks()
        try await syncProjects()
        try await syncEpics()
    }
    
    // MARK: - 任务同步
    
    private func syncTasks() async throws {
        // 获取本地任务
        let localTasks = await dataManager.tasks
        
        // 获取云端任务
        let cloudTasks = try await fetchCloudTasks()
        
        // 合并任务
        try await mergeTasks(local: localTasks, cloud: cloudTasks)
    }
    
    private func fetchCloudTasks() async throws -> [XTask] {
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return try result.matchResults.compactMap { (_, res) in
            switch res {
            case .success(let record):
                return XTask.fromRecord(record)
            case .failure:
                return nil
            }
        }
    }
    
    private func mergeTasks(local: [XTask], cloud: [XTask]) async throws {
        // 创建任务ID映射
        var localTaskMap = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        var cloudTaskMap = Dictionary(uniqueKeysWithValues: cloud.map { ($0.id, $0) })
        
        // 处理新增和更新
        for cloudTask in cloud {
            if let localTask = localTaskMap[cloudTask.id] {
                // 更新本地任务
                if cloudTask.updatedAt > localTask.updatedAt {
                    try await updateLocalTask(localTask, with: cloudTask)
                }
            } else {
                // 添加新任务到本地
                try await addTaskLocally(cloudTask)
            }
            cloudTaskMap.removeValue(forKey: cloudTask.id)
        }
        
        // 处理删除
        for localTask in local where cloudTaskMap[localTask.id] == nil {
            try await deleteTaskLocally(localTask)
        }
    }
    
    private func updateLocalTask(_ local: XTask, with cloud: XTask) async throws {
        var updatedTask = local
        updatedTask.title = cloud.title
        updatedTask.startDate = cloud.startDate
        updatedTask.endDate = cloud.endDate
        updatedTask.priority = cloud.priority
        updatedTask.status = cloud.status
        updatedTask.reminderDate = cloud.reminderDate
        updatedTask.notes = cloud.notes
        updatedTask.isCompleted = cloud.isCompleted
        updatedTask.dueDate = cloud.dueDate
        updatedTask.updatedAt = cloud.updatedAt
        updatedTask.completedAt = cloud.completedAt
        
        try await dataManager.updateTask(updatedTask)
    }
    
    private func addTaskLocally(_ task: XTask) async throws {
        try await dataManager.createTask(task)
    }
    
    private func deleteTaskLocally(_ task: XTask) async throws {
        try await dataManager.deleteTask(task)
    }
    
    // MARK: - 项目同步
    
    private func syncProjects() async throws {
        let localProjects = await dataManager.projects
        let cloudProjects = try await fetchCloudProjects()
        try await mergeProjects(local: localProjects, cloud: cloudProjects)
    }
    
    private func fetchCloudProjects() async throws -> [Project] {
        let query = CKQuery(recordType: "Project", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return try result.matchResults.compactMap { (_, res) in
            switch res {
            case .success(let record):
                return Project.fromRecord(record)
            case .failure:
                return nil
            }
        }
    }
    
    private func mergeProjects(local: [Project], cloud: [Project]) async throws {
        // 实现项目合并逻辑，类似任务合并
        var localProjectMap = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        var cloudProjectMap = Dictionary(uniqueKeysWithValues: cloud.map { ($0.id, $0) })
        
        for cloudProject in cloud {
            if let localProject = localProjectMap[cloudProject.id] {
                if cloudProject.updatedAt > localProject.updatedAt {
                    try await dataManager.updateProject(cloudProject)
                }
            } else {
                try await dataManager.createProject(cloudProject)
            }
            cloudProjectMap.removeValue(forKey: cloudProject.id)
        }
        
        for localProject in local where cloudProjectMap[localProject.id] == nil {
            try await dataManager.deleteProject(localProject)
        }
    }
    
    // MARK: - 史诗同步
    
    private func syncEpics() async throws {
        let localEpics = await dataManager.epics
        let cloudEpics = try await fetchCloudEpics()
        try await mergeEpics(local: localEpics, cloud: cloudEpics)
    }
    
    private func fetchCloudEpics() async throws -> [Epic] {
        let query = CKQuery(recordType: "Epic", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        return try result.matchResults.compactMap { (_, res) in
            switch res {
            case .success(let record):
                return Epic.fromRecord(record)
            case .failure:
                return nil
            }
        }
    }
    
    private func mergeEpics(local: [Epic], cloud: [Epic]) async throws {
        // 实现史诗合并逻辑，类似任务合并
        var localEpicMap = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        var cloudEpicMap = Dictionary(uniqueKeysWithValues: cloud.map { ($0.id, $0) })
        
        for cloudEpic in cloud {
            if let localEpic = localEpicMap[cloudEpic.id] {
                if cloudEpic.updatedAt > localEpic.updatedAt {
                    try await dataManager.updateEpic(cloudEpic)
                }
            } else {
                try await dataManager.createEpic(cloudEpic)
            }
            cloudEpicMap.removeValue(forKey: cloudEpic.id)
        }
        
        for localEpic in local where cloudEpicMap[localEpic.id] == nil {
            try await dataManager.deleteEpic(localEpic)
        }
    }
    
    // MARK: - 变更处理
    
    @objc private func handleDatabaseChanges() {
        DispatchQueue.main.async { [weak self] in
            self?.startSyncAsync()
        }
    }
    
    private func startSyncAsync() {
        _ = _Concurrency.Task { [weak self] in
            do {
                try await self?.startSync()
            } catch {
                print("同步失败: \(error)")
            }
        }
    }
}

// MARK: - CloudKit 转换静态方法

extension XTask {
    static func fromRecord(_ record: CKRecord) -> XTask? {
        guard let idStr = record["id"] as? String,
              let id = UUID(uuidString: idStr),
              let title = record["title"] as? String,
              let priorityRaw = record["priority"] as? Int,
              let statusRaw = record["status"] as? String,
              let isCompleted = record["isCompleted"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else { return nil }
        
        var task = XTask(
            id: id,
            title: title,
            startDate: record["startDate"] as? Date,
            endDate: record["endDate"] as? Date,
            priority: TaskPriority(rawValue: priorityRaw) ?? .normal,
            status: TaskStatus(rawValue: statusRaw) ?? .todo,
            reminderDate: record["reminderDate"] as? Date,
            notes: record["notes"] as? String,
            isCompleted: isCompleted,
            dueDate: record["dueDate"] as? Date
        )
        // 手动设置时间戳，因为初始化器会覆盖它们
        task.createdAt = createdAt
        task.updatedAt = updatedAt
        task.completedAt = record["completedAt"] as? Date
        return task
    }
    
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Task")
        record["id"] = id.uuidString as CKRecordValue
        record["title"] = title as CKRecordValue
        record["startDate"] = startDate as? CKRecordValue
        record["endDate"] = endDate as? CKRecordValue
        record["priority"] = priority.rawValue as CKRecordValue
        record["status"] = status.rawValue as CKRecordValue
        record["reminderDate"] = reminderDate as? CKRecordValue
        record["notes"] = notes as? CKRecordValue
        record["isCompleted"] = isCompleted as CKRecordValue
        record["dueDate"] = dueDate as? CKRecordValue
        record["createdAt"] = createdAt as CKRecordValue
        record["updatedAt"] = updatedAt as CKRecordValue
        record["completedAt"] = completedAt as? CKRecordValue
        return record
    }
}

extension Project {
    static func fromRecord(_ record: CKRecord) -> Project? {
        guard let idStr = record["id"] as? String,
              let id = UUID(uuidString: idStr),
              let name = record["name"] as? String else { return nil }
        return Project(
            id: id,
            name: name,
            description: record["description"] as? String ?? ""
        )
    }
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Project")
        record["id"] = id.uuidString as CKRecordValue
        record["name"] = name as CKRecordValue
        record["description"] = description as CKRecordValue
        return record
    }
}

extension Epic {
    static func fromRecord(_ record: CKRecord) -> Epic? {
        guard let idStr = record["id"] as? String,
              let id = UUID(uuidString: idStr),
              let name = record["name"] as? String else { return nil }
        return Epic(
            id: id,
            name: name,
            description: record["description"] as? String ?? ""
        )
    }
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Epic")
        record["id"] = id.uuidString as CKRecordValue
        record["name"] = name as CKRecordValue
        record["description"] = description as CKRecordValue
        return record
    }
} 
