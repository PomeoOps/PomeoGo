import SwiftUI

struct TaskSubtaskSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    @Binding var isAddingSubtask: Bool
    
    var body: some View {
        Section(header: Text("子任务")) {
            let subtasks = viewModel.getSubtasks(for: task.dependencyIds)
            ForEach(subtasks) { subtask in
                NavigationLink(destination: TaskDetailPanelView(task: subtask, viewModel: viewModel)) {
                    TaskRowView(task: subtask)
                }
            }
            
            Button(action: { isAddingSubtask = true }) {
                Label("添加子任务", systemImage: "plus.circle")
            }
        }
    }
}

#Preview {
    List {
        TaskSubtaskSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared),
            isAddingSubtask: .constant(false)
        )
    }
} 