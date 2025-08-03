import Foundation

// 核心附件模型，移除SwiftData依赖
struct Attachment: Identifiable, Codable, Hashable {
    let id: UUID
    var fileName: String
    var filePath: String
    var fileSize: Int64
    var type: AttachmentType
    var createdAt: Date
    var updatedAt: Date
    
    // 版本控制
    var version: Int
    
    init(
        id: UUID = UUID(),
        fileName: String,
        filePath: String,
        fileSize: Int64,
        type: AttachmentType,
        version: Int = 1
    ) {
        self.id = id
        self.fileName = fileName
        self.filePath = filePath
        self.fileSize = fileSize
        self.type = type
        self.createdAt = Date()
        self.updatedAt = Date()
        self.version = version
    }
    
    // MARK: - 业务方法
    mutating func updateFileName(_ newFileName: String) {
        fileName = newFileName
        updatedAt = Date()
        version += 1
    }
    
    mutating func updateFilePath(_ newFilePath: String) {
        filePath = newFilePath
        updatedAt = Date()
        version += 1
    }
    
    mutating func updateFileSize(_ newFileSize: Int64) {
        fileSize = newFileSize
        updatedAt = Date()
        version += 1
    }
    
    // MARK: - 计算属性
    var displayName: String {
        return fileName.isEmpty ? "未命名文件" : fileName
    }
    
    var formattedFileSize: String {
        return formatFileSize(fileSize)
    }
    
    var fileExtension: String {
        return (fileName as NSString).pathExtension.lowercased()
    }
    
    var isImage: Bool {
        return type == .image
    }
    
    var isDocument: Bool {
        return type == .document
    }
    
    var isVideo: Bool {
        return type == .video
    }
    
    var isAudio: Bool {
        return type == .audio
    }
    
    var isText: Bool {
        return type == .text || type == .markdown
    }
    
    // MARK: - 私有方法
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - 附件类型枚举
enum AttachmentType: String, Codable, CaseIterable {
    case image = "image"
    case document = "document"
    case video = "video"
    case audio = "audio"
    case text = "text"
    case markdown = "markdown"
    case other = "other"
    
    var icon: String {
        switch self {
        case .image: return "photo"
        case .document: return "doc.text"
        case .video: return "video"
        case .audio: return "music.note"
        case .text: return "text.alignleft"
        case .markdown: return "textformat"
        case .other: return "paperclip"
        }
    }
    
    var title: String {
        switch self {
        case .image: return "图片"
        case .document: return "文档"
        case .video: return "视频"
        case .audio: return "音频"
        case .text: return "文本"
        case .markdown: return "Markdown"
        case .other: return "其他"
        }
    }
    
    var color: String {
        switch self {
        case .image: return "blue"
        case .document: return "green"
        case .video: return "purple"
        case .audio: return "orange"
        case .text: return "gray"
        case .markdown: return "cyan"
        case .other: return "gray"
        }
    }
    
    // 根据文件扩展名推断类型
    static func inferType(from fileName: String) -> AttachmentType {
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        switch fileExtension {
        case "jpg", "jpeg", "png", "gif", "bmp", "webp":
            return .image
        case "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx":
            return .document
        case "mp4", "mov", "avi", "mkv", "wmv":
            return .video
        case "mp3", "wav", "aac", "flac":
            return .audio
        case "txt", "rtf":
            return .text
        case "md", "markdown":
            return .markdown
        default:
            return .other
        }
    }
} 