import SwiftUI

struct TaskTitleSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        let isCompleted = task.isCompleted
        let title = task.title
        let titleBinding = $task.title
        
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title2)
                .onTapGesture {
                    _Concurrency.Task {
                        do {
                            if isCompleted {
                                try await viewModel.reopenTask(task)
                            } else {
                                try await viewModel.completeTask(task)
                            }
                        } catch {
                            print("操作失败: \(error)")
                        }
                    }
                }
            
            TextField("任务标题", text: titleBinding)
                .font(.body)
                .textFieldStyle(.plain)
                .onChange(of: title) { oldValue, newValue in
                    _Concurrency.Task {
                        do {
                            try await viewModel.updateTask(task)
                        } catch {
                            print("更新任务失败: \(error)")
                        }
                    }
                }
        }
    }
}

#Preview {
    TaskTitleSection(
        task: XTask(title: "示例任务"),
        viewModel: TaskViewModel(dataManager: DataManager.shared)
    )
    .padding()
} 