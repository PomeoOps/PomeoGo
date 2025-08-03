import SwiftUI

struct AttachmentRowView: View {
    let attachment: Attachment
    
    var body: some View {
        HStack {
            // 文件图标
            Image(systemName: getFileIcon())
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            // 文件信息
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                Text(attachment.formattedFileSize)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 操作按钮
            HStack(spacing: 8) {
                Button("打开") {
                    openFile()
                }
                .buttonStyle(.bordered)
                
                Button("删除") {
                    deleteFile()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getFileIcon() -> String {
        switch attachment.type {
        case .text: return "doc.text"
        case .markdown: return "doc.text"
        case .image: return "photo"
        case .document: return "doc.text"
        case .video: return "video"
        case .audio: return "music.note"
        case .other: return "paperclip"
        }
    }
    
    private func openFile() {
        // 实现文件打开逻辑
        print("打开文件: \(attachment.fileName)")
    }
    
    private func deleteFile() {
        // 实现文件删除逻辑
        print("删除文件: \(attachment.fileName)")
    }
}

#Preview {
    List {
        AttachmentRowView(attachment: Attachment(
            fileName: "test.txt",
            filePath: "/test.txt",
            fileSize: 1024,
            type: .text
        ))
    }
} 