import SwiftUI

struct TaskDetailPanelView: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isAddingSubtask = false
    @State private var isAddingAttachment = false
    @State private var newChecklistItem = ""
    
    var body: some View {
        List {
            TaskTitleSection(task: task, viewModel: viewModel)
            TaskDateSection(task: task, viewModel: viewModel)
            TaskPriorityStatusSection(task: task, viewModel: viewModel)
            TaskChecklistSection(task: task, viewModel: viewModel, newChecklistItem: $newChecklistItem)
            TaskSubtaskSection(task: task, viewModel: viewModel, isAddingSubtask: $isAddingSubtask)
            TaskAttachmentSection(task: task)
            TaskNotesSection(task: task, viewModel: viewModel)
            TaskInfoSection(task: task)
            TaskDeleteSection(task: task, viewModel: viewModel)
        }
        .listStyle(.inset)
        .navigationTitle("任务详情")
        .sheet(isPresented: $isAddingSubtask) {
            AddTaskSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isAddingAttachment) {
            AddAttachmentSheet(viewModel: viewModel, task: task)
        }
    }
}

#Preview {
    NavigationView {
        TaskDetailPanelView(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared)
        )
    }
} 