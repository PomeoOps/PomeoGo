import SwiftUI

struct TaskChecklistSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    @Binding var newChecklistItem: String
    
    var body: some View {
        let checklistItems = viewModel.getChecklistItems(for: task.checklistItemIds)
        let completedCount = checklistItems.filter { $0.isCompleted }.count
        let totalCount = checklistItems.count
        let progressText = "\(completedCount)/\(totalCount)"
        
        Section(header: HStack {
            Text("检查清单")
            Spacer()
            Text(progressText)
                .foregroundColor(.gray)
        }) {
            ForEach(checklistItems.indices, id: \.self) { index in
                let item = checklistItems[index]
                let isCompleted = item.isCompleted
                HStack {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isCompleted ? .green : .gray)
                        .onTapGesture {
                            _Concurrency.Task {
                                do {
                                    var updatedItem = item
                                    updatedItem.isCompleted.toggle()
                                    try await viewModel.updateChecklistItem(updatedItem)
                                } catch {
                                    print("更新检查清单项目失败: \(error)")
                                }
                            }
                        }
                    TextField("项目内容", text: Binding(
                        get: { item.title },
                        set: { newValue in
                            _Concurrency.Task {
                                do {
                                    var updatedItem = item
                                    updatedItem.title = newValue
                                    try await viewModel.updateChecklistItem(updatedItem)
                                } catch {
                                    print("更新检查清单项目失败: \(error)")
                                }
                            }
                        }
                    ))
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = checklistItems[index]
                    _Concurrency.Task {
                        do {
                            try await viewModel.deleteChecklistItem(item)
                        } catch {
                            print("删除检查清单项目失败: \(error)")
                        }
                    }
                }
            }
            
            HStack {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
                TextField("添加新项目", text: $newChecklistItem)
                    .onSubmit {
                        if !newChecklistItem.isEmpty {
                            _Concurrency.Task {
                                do {
                                    let newItem = ChecklistItem(title: newChecklistItem)
                                    try await viewModel.addChecklistItem(newItem, to: task)
                                    await MainActor.run {
                                        newChecklistItem = ""
                                    }
                                } catch {
                                    print("添加检查清单项目失败: \(error)")
                                }
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    List {
        TaskChecklistSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared),
            newChecklistItem: .constant("")
        )
    }
} 