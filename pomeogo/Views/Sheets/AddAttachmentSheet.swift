import SwiftUI
import Foundation
import UniformTypeIdentifiers

// AddAttachmentSheet - 现代化设计
struct AddAttachmentSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: XTask
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFiles: [URL] = []
    @State private var isFilePickerPresented = false
    @State private var attachmentName = ""
    @State private var attachmentDescription = ""
    @State private var attachmentType: AttachmentType = .document
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 附件类型选择
                    attachmentTypeCard
                    
                    // 文件选择
                    fileSelectionCard
                    
                    // 附件信息
                    attachmentInfoCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(groupBgColor)
            .navigationTitle("添加附件")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { 
                        dismiss() 
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        addAttachment()
                    }
                    .disabled(selectedFiles.isEmpty)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(width: 600, height: 500)
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                selectedFiles = urls
            case .failure(let error):
                print("文件选择失败: \(error.localizedDescription)")
            }
        }
    }
    
    private var attachmentTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paperclip.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("附件类型")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach(AttachmentType.allCases, id: \.self) { type in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            attachmentType = type
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundColor(attachmentType == type ? .white : .blue)
                            
                            Text(type.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(attachmentType == type ? .white : .blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(attachmentType == type ? .blue : .blue.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.blue, lineWidth: attachmentType == type ? 0 : 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var fileSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("选择文件")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Button(action: {
                isFilePickerPresented = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("选择文件")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(controlBgColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if !selectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("已选择的文件:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(selectedFiles, id: \.self) { url in
                        HStack {
                            Image(systemName: "doc")
                                .foregroundColor(.blue)
                            Text(url.lastPathComponent)
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(controlBgColor)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var attachmentInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("附件信息")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("附件名称（可选）", text: $attachmentName)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(controlBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                
                TextField("附件描述（可选）", text: $attachmentDescription)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(controlBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private func addAttachment() {
        _Concurrency.Task {
            do {
                for fileURL in selectedFiles {
                    // 获取文件大小
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                    let fileSize = fileAttributes[.size] as? Int64 ?? 0
                    
                    // 推断文件类型
                    let fileName = attachmentName.isEmpty ? fileURL.lastPathComponent : attachmentName
                    let attachmentType = AttachmentType.inferType(from: fileName)
                    
                    let attachment = Attachment(
                        fileName: fileName,
                        filePath: fileURL.path,
                        fileSize: fileSize,
                        type: attachmentType
                    )
                    
                    // 这里需要实现将附件添加到任务的逻辑
                    // 由于Task模型没有attachments属性，我们需要通过其他方式管理附件
                    print("创建附件: \(attachment.fileName)")
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("添加附件失败: \(error)")
            }
        }
    }
} 