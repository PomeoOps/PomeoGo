import SwiftUI

struct TaskPriorityStatusSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        Section {
            // 优先级选择器
            Picker("优先级", selection: $task.priority) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Label(priority.title, systemImage: priority.icon)
                        .tag(priority)
                }
            }
            .onChange(of: task.priority) { oldValue, newValue in
                _Concurrency.Task {
                    try? await viewModel.updateTask(task)
                }
            }
            
            // 状态选择器
            Picker("状态", selection: $task.status) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    Label(status.rawValue, systemImage: status.icon)
                        .tag(status)
                }
            }
            .onChange(of: task.status) { oldValue, newValue in
                _Concurrency.Task {
                    try? await viewModel.updateTask(task)
                }
            }
        }
    }
}

#Preview {
    List {
        TaskPriorityStatusSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared)
        )
    }
} 