/*
import Foundation

// MARK: - 数据迁移器
// 用于从旧版本的数据模型迁移到新版本
class DataMigrator {
    private let oldDataManager: DataManager
    private let newDataManager: DataManager
    
    init(oldDataManager: DataManager, newDataManager: DataManager) {
        self.oldDataManager = oldDataManager
        self.newDataManager = newDataManager
    }
    
    // MARK: - 迁移状态
    enum MigrationStatus {
        case success(migratedCount: Int, failedCount: Int)
        case failed(String)
    }
    
    // MARK: - 主迁移方法
    
    func migrateAllData() async throws -> [String: MigrationStatus] {
        print("开始数据迁移...")
        
        var results: [String: MigrationStatus] = [:]
        
        // 迁移各种数据类型
        results["tasks"] = try await migrateTasks()
        results["projects"] = try await migrateProjects()
        results["epics"] = try await migrateEpics()
        results["tags"] = try await migrateTags()
        results["attachments"] = try await migrateAttachments()
        results["checklistItems"] = try await migrateChecklistItems()
        
        print("数据迁移完成")
        return results
    }
    
    // MARK: - 具体迁移方法
    
    private func migrateTasks() async throws -> MigrationStatus {
        print("开始迁移任务数据...")
        
        // 从旧数据管理器获取任务
        let oldTasks = oldDataManager.fetchTasks()
        var migratedCount = 0
        var failedCount = 0
        
        for oldTask in oldTasks {
            do {
                // 转换为新的Task模型
                let newTask = convertToNewXTask(oldTask)
                
                // 保存到新数据管理器
                try await newDataManager.createTask(newTask)
                migratedCount += 1
                
                print("成功迁移任务: \(oldXTask.title)")
            } catch {
                failedCount += 1
                print("迁移任务失败: \(oldXTask.title), 错误: \(error)")
            }
        }
        
        print("任务迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    private func migrateProjects() async throws -> MigrationStatus {
        print("开始迁移项目数据...")
        
        let oldProjects = oldDataManager.fetchProjects()
        var migratedCount = 0
        var failedCount = 0
        
        for oldProject in oldProjects {
            do {
                let newProject = convertToNewProject(oldProject)
                try await newDataManager.createProject(newProject)
                migratedCount += 1
                
                print("成功迁移项目: \(oldProject.name)")
            } catch {
                failedCount += 1
                print("迁移项目失败: \(oldProject.name), 错误: \(error)")
            }
        }
        
        print("项目迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    private func migrateEpics() async throws -> MigrationStatus {
        print("开始迁移史诗数据...")
        
        let oldEpics = oldDataManager.fetchEpics()
        var migratedCount = 0
        var failedCount = 0
        
        for oldEpic in oldEpics {
            do {
                let newEpic = convertToNewEpic(oldEpic)
                try await newDataManager.createEpic(newEpic)
                migratedCount += 1
                
                print("成功迁移史诗: \(oldEpic.name)")
            } catch {
                failedCount += 1
                print("迁移史诗失败: \(oldEpic.name), 错误: \(error)")
            }
        }
        
        print("史诗迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    private func migrateTags() async throws -> MigrationStatus {
        print("开始迁移标签数据...")
        
        let oldTags = oldDataManager.fetchTags()
        var migratedCount = 0
        var failedCount = 0
        
        for oldTag in oldTags {
            do {
                let newTag = convertToNewTag(oldTag)
                try await newDataManager.createTag(newTag)
                migratedCount += 1
                
                print("成功迁移标签: \(oldTag.name)")
            } catch {
                failedCount += 1
                print("迁移标签失败: \(oldTag.name), 错误: \(error)")
            }
        }
        
        print("标签迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    private func migrateAttachments() async throws -> MigrationStatus {
        print("开始迁移附件数据...")
        
        let oldAttachments = oldDataManager.fetchAttachments()
        var migratedCount = 0
        var failedCount = 0
        
        for oldAttachment in oldAttachments {
            do {
                let newAttachment = convertToNewAttachment(oldAttachment)
                try await newDataManager.createAttachment(newAttachment)
                migratedCount += 1
                
                print("成功迁移附件: \(oldAttachment.fileName)")
            } catch {
                failedCount += 1
                print("迁移附件失败: \(oldAttachment.fileName), 错误: \(error)")
            }
        }
        
        print("附件迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    private func migrateChecklistItems() async throws -> MigrationStatus {
        print("开始迁移检查项数据...")
        
        let oldChecklistItems = oldDataManager.fetchChecklistItems()
        var migratedCount = 0
        var failedCount = 0
        
        for oldItem in oldChecklistItems {
            do {
                let newItem = convertToNewChecklistItem(oldItem)
                try await newDataManager.createChecklistItem(newItem)
                migratedCount += 1
                
                print("成功迁移检查项: \(oldItem.title)")
            } catch {
                failedCount += 1
                print("迁移检查项失败: \(oldItem.title), 错误: \(error)")
            }
        }
        
        print("检查项迁移完成: 成功 \(migratedCount) 个, 失败 \(failedCount) 个")
        return .success(migratedCount: migratedCount, failedCount: failedCount)
    }
    
    // MARK: - 数据转换方法
    
    private func convertToNewXTask(_ oldTask: XTask -> Task {
        return XTask(
            id: oldXTask.id,
            title: oldXTask.title,
            startDate: oldXTask.startDate,
            endDate: oldXTask.endDate,
            priority: convertTaskPriority(oldXTask.priority),
            status: convertTaskStatus(oldXTask.status),
            reminderDate: oldXTask.reminderDate,
            locationEnabled: oldXTask.locationEnabled,
            locationLat: oldXTask.locationLat,
            locationLng: oldXTask.locationLng,
            locationAddress: oldXTask.locationAddress,
            repeatEnabled: oldXTask.repeatEnabled,
            repeatType: convertRepeatType(oldXTask.repeatType),
            repeatInterval: oldXTask.repeatInterval,
            repeatEndDate: oldXTask.repeatEndDate,
            parentId: oldXTask.parent?.id,
            projectId: oldXTask.project?.id,
            epicId: oldXTask.epic?.id,
            tagIds: oldXTask.tags.map { $0.id },
            dependencyIds: oldXTask.dependencyIds,
            notes: oldXTask.notes,
            checklistItemIds: oldXTask.checklistItems.map { $0.id },
            attachmentIds: oldXTask.attachments.map { $0.id },
            isCompleted: oldXTask.isCompleted,
            dueDate: oldXTask.dueDate,
            estimatedHours: oldXTask.estimatedHours,
            actualHours: oldXTask.actualHours,
            assignee: oldXTask.assignee,
            version: oldXTask.version
        )
    }
    
    private func convertToNewProject(_ oldProject: Project) -> Project {
        return Project(
            id: oldProject.id,
            name: oldProject.name,
            projectDescription: oldProject.projectDescription,
            color: oldProject.color,
            epicId: oldProject.epic?.id,
            startDate: oldProject.startDate,
            endDate: oldProject.endDate,
            estimatedHours: oldProject.estimatedHours,
            actualHours: oldProject.actualHours,
            progress: oldProject.progress,
            isCompleted: oldProject.isCompleted,
            assignee: oldProject.assignee,
            isArchived: oldProject.isArchived,
            completedAt: oldProject.completedAt,
            archivedAt: oldProject.archivedAt,
            version: oldProject.version
        )
    }
    
    private func convertToNewEpic(_ oldEpic: Epic) -> Epic {
        return Epic(
            id: oldEpic.id,
            name: oldEpic.name,
            epicDescription: oldEpic.epicDescription,
            color: oldEpic.color,
            startDate: oldEpic.startDate,
            endDate: oldEpic.endDate,
            estimatedHours: oldEpic.estimatedHours,
            actualHours: oldEpic.actualHours,
            progress: oldEpic.progress,
            isCompleted: oldEpic.isCompleted,
            assignee: oldEpic.assignee,
            isArchived: oldEpic.isArchived,
            completedAt: oldEpic.completedAt,
            archivedAt: oldEpic.archivedAt,
            version: oldEpic.version
        )
    }
    
    private func convertToNewTag(_ oldTag: Tag) -> Tag {
        return Tag(
            id: oldTag.id,
            name: oldTag.name,
            color: oldTag.color,
            description: oldTag.description,
            version: oldTag.version
        )
    }
    
    private func convertToNewAttachment(_ oldAttachment: Attachment) -> Attachment {
        return Attachment(
            id: oldAttachment.id,
            fileName: oldAttachment.fileName,
            filePath: oldAttachment.filePath,
            fileSize: oldAttachment.fileSize,
            fileType: convertAttachmentType(oldAttachment.fileType),
            taskId: oldAttachment.task?.id,
            projectId: oldAttachment.project?.id,
            epicId: oldAttachment.epic?.id,
            version: oldAttachment.version
        )
    }
    
    private func convertToNewChecklistItem(_ oldItem: ChecklistItem) -> ChecklistItem {
        return ChecklistItem(
            id: oldItem.id,
            title: oldItem.title,
            isCompleted: oldItem.isCompleted,
            taskId: oldItem.task?.id,
            order: oldItem.order,
            notes: oldItem.notes,
            version: oldItem.version
        )
    }
    
    // MARK: - 枚举转换方法
    
    private func convertTaskStatus(_ oldStatus: TaskStatus) -> TaskStatus {
        switch oldStatus {
        case .todo: return .todo
        case .inProgress: return .inProgress
        case .completed: return .completed
        case .cancelled: return .cancelled
        }
    }
    
    private func convertTaskPriority(_ oldPriority: TaskPriority) -> TaskPriority {
        switch oldPriority {
        case .low: return .low
        case .normal: return .normal
        case .high: return .high
        case .urgent: return .urgent
        }
    }
    
    private func convertRepeatType(_ oldType: RepeatType) -> RepeatType {
        switch oldType {
        case .none: return .none
        case .daily: return .daily
        case .weekly: return .weekly
        case .monthly: return .monthly
        case .yearly: return .yearly
        }
    }
    
    private func convertAttachmentType(_ oldType: AttachmentType) -> AttachmentType {
        switch oldType {
        case .image: return .image
        case .document: return .document
        case .video: return .video
        case .audio: return .audio
        case .other: return .other
        }
    }
}
*/ 