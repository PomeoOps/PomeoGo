import SwiftUI
import Foundation

// 这个文件现在只包含对其他拆分文件的引用
// 主要的Sheet组件已经被拆分到 Views/Sheets/ 目录下

// 保留一些小的辅助组件
struct CreateTextFileSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: XTask
    @Environment(\.dismiss) private var dismiss
    
    @State private var fileName = ""
    @State private var fileContent = ""
    @FocusState private var fileNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("文件名", text: $fileName)
                    .textFieldStyle(.roundedBorder)
                    .focused($fileNameFocused)
                
                TextEditor(text: $fileContent)
                    .frame(height: 300)
                    .border(.gray.opacity(0.3))
                
                Spacer()
            }
            .padding()
            .navigationTitle("创建文本文件")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createTextFile()
                    }
                    .disabled(fileName.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            fileNameFocused = true
        }
    }
    
    private func createTextFile() {
        // 创建文本文件的逻辑
        dismiss()
    }
}

struct EditEpicSheet: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    let epic: Epic
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    
    init(projectViewModel: ProjectViewModel, epic: Epic) {
        self.projectViewModel = projectViewModel
        self.epic = epic
        self._name = State(initialValue: epic.name)
        self._description = State(initialValue: epic.description)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("EPIC名称", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .border(.gray.opacity(0.3))
                
                Spacer()
            }
            .padding()
            .navigationTitle("编辑EPIC")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateEpic()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 300)
    }
    
    private func updateEpic() {
        // 更新EPIC的逻辑
        dismiss()
    }
}

struct EditProjectSheet: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    let project: Project
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    
    init(projectViewModel: ProjectViewModel, project: Project) {
        self.projectViewModel = projectViewModel
        self.project = project
        self._name = State(initialValue: project.name)
        self._description = State(initialValue: project.description)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("项目名称", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .border(.gray.opacity(0.3))
                
                Spacer()
            }
            .padding()
            .navigationTitle("编辑项目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 300)
    }
    
    private func updateProject() {
        // 更新项目的逻辑
        dismiss()
    }
}

struct EditTaskSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    let task: XTask
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    
    init(viewModel: TaskViewModel, task: XTask) {
        self.viewModel = viewModel
        self.task = task
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("任务标题", text: $title)
                    .textFieldStyle(.roundedBorder)
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .border(.gray.opacity(0.3))
                
                Spacer()
            }
            .padding()
            .navigationTitle("编辑任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        updateTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 300)
    }
    
    private func updateTask() {
        // 更新任务的逻辑
        dismiss()
    }
} 