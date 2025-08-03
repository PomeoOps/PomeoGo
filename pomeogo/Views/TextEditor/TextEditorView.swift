import SwiftUI

struct TextEditorView: View {
    let attachment: Attachment
    @State private var content: String = ""
    @State private var isEditing = false
    @State private var showingSaveAlert = false
    @State private var saveAlertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 工具栏
            HStack {
                HStack(spacing: 16) {
                    // 文件信息
                    HStack(spacing: 8) {
                        Image(systemName: attachment.type.icon)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(attachment.fileName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(formatFileSize(attachment.fileSize))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // 编辑状态指示器
                    if isEditing {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            Text("编辑中")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // 操作按钮
                HStack(spacing: 12) {
                    if isEditing {
                        Button("取消") {
                            cancelEditing()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("保存") {
                            saveContent()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("编辑") {
                            startEditing()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(groupBgColor)
            .border(Color.gray.opacity(0.3), width: 0.5)
            
            // 编辑器内容
            if isEditing {
                TextEditor(text: $content)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(groupBgColor)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(parseMarkdown(content), id: \.self) { element in
                            MarkdownElementView(element: element)
                        }
                    }
                    .padding()
                }
                .background(groupBgColor)
            }
        }
        .onAppear {
            loadContent()
        }
        .alert("保存结果", isPresented: $showingSaveAlert) {
            Button("确定") { }
        } message: {
            Text(saveAlertMessage)
        }
    }
    
    private func loadContent() {
        // 简化实现，直接读取文件内容
        do {
            content = try String(contentsOfFile: attachment.filePath, encoding: .utf8)
        } catch {
            content = "无法加载文件内容"
        }
    }
    
    private func saveContent() {
        do {
            try content.write(toFile: attachment.filePath, atomically: true, encoding: .utf8)
            isEditing = false
            saveAlertMessage = "文件保存成功"
        } catch {
            saveAlertMessage = "文件保存失败"
        }
        showingSaveAlert = true
    }
    
    private func startEditing() {
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        loadContent() // 重新加载原始内容
    }
    
    private func formatFileSize(_ size: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            if trimmedLine.hasPrefix("# ") {
                elements.append(MarkdownElement(type: .header1, content: String(trimmedLine.dropFirst(2))))
            } else if trimmedLine.hasPrefix("## ") {
                elements.append(MarkdownElement(type: .header2, content: String(trimmedLine.dropFirst(3))))
            } else if trimmedLine.hasPrefix("### ") {
                elements.append(MarkdownElement(type: .header3, content: String(trimmedLine.dropFirst(4))))
            } else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                elements.append(MarkdownElement(type: .listItem, content: String(trimmedLine.dropFirst(2))))
            } else if trimmedLine.hasPrefix("```") {
                elements.append(MarkdownElement(type: .code, content: trimmedLine))
            } else {
                elements.append(MarkdownElement(type: .paragraph, content: trimmedLine))
            }
        }
        
        return elements
    }
}

struct MarkdownElementView: View {
    let element: MarkdownElement
    
    var body: some View {
        switch element.type {
        case .header1:
            Text(element.content)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.vertical, 4)
        case .header2:
            Text(element.content)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.vertical, 3)
        case .header3:
            Text(element.content)
                .font(.title2)
                .fontWeight(.medium)
                .padding(.vertical, 2)
        case .paragraph:
            Text(element.content)
                .font(.body)
                .padding(.vertical, 1)
        case .code:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(groupBgColor)
                .cornerRadius(4)
        case .listItem:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.body)
                    .foregroundColor(.secondary)
                Text(element.content)
                    .font(.body)
            }
            .padding(.vertical, 1)
        }
    }
}

