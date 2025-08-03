import SwiftUI

struct TaskAttachmentSection: View {
    let task: XTask
    @State private var showingAttachmentPicker = false
    @State private var showingTextEditor = false
    @State private var selectedAttachment: Attachment?
    
    var body: some View {
        Section("附件") {
            if task.attachmentIds.isEmpty {
                Text("暂无附件")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                // 这里需要从数据管理器获取附件数据
                Text("附件数量: \(task.attachmentIds.count)")
                    .foregroundColor(.secondary)
            }
            
            Button("添加附件") {
                showingAttachmentPicker = true
            }
        }
        .sheet(isPresented: $showingTextEditor) {
            if let selectedAttachment = selectedAttachment {
                TextEditorView(attachment: selectedAttachment)
            }
        }
    }
    
    private func handleAttachmentTap(_ attachment: Attachment) {
        let fileExtension = attachment.fileExtension
        if fileExtension == "md" || fileExtension == "txt" {
            selectedAttachment = attachment
            showingTextEditor = true
        }
    }
    
    private func convertToAttachment(_ attachment: Attachment) -> Attachment {
        let fileExtension = attachment.fileExtension
        let attachmentType: AttachmentType
        switch fileExtension {
        case "md": attachmentType = .markdown
        case "txt": attachmentType = .text
        default: attachmentType = .text
        }
        
        return Attachment(
            fileName: attachment.fileName,
            filePath: attachment.filePath,
            fileSize: attachment.fileSize,
            type: attachmentType
        )
    }
    
    private func getFileSize(_ url: URL) -> Int64 {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
}

struct TaskAttachmentSection_Previews: PreviewProvider {
    static var previews: some View {
        TaskAttachmentSection(task: XTask(title: "测试任务"))
    }
} 