import SwiftUI

struct TaskNotesSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        Section(header: Text("备注")) {
            TextEditor(text: Binding(
                get: { task.notes ?? "" },
                set: { 
                    task.notes = $0
                    _Concurrency.Task { try? await viewModel.updateTask(task) }
                }
            ))
            .frame(minHeight: 100)
        }
    }
}

#Preview {
    List {
        TaskNotesSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared)
        )
    }
} 