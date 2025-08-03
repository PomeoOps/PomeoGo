import SwiftUI

struct TextEditorView_Previews: PreviewProvider {
    static var previews: some View {
        TextEditorView(attachment: Attachment(
            id: UUID(),
            fileName: "示例文档.md",
            filePath: "/path/to/file.md",
            fileSize: 1024,
            type: .markdown,
            
        ))
    }
} 