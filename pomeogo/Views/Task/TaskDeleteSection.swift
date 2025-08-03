import SwiftUI

struct TaskDeleteSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Section {
            Button("删除任务") {
                _Concurrency.Task {
                    do {
                        try await viewModel.deleteTask(task)
                        dismiss()
                    } catch {
                        print("删除任务失败: \(error)")
                    }
                }
            }
            .foregroundColor(.red)
        }
    }
}

#Preview {
    List {
        TaskDeleteSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared)
        )
    }
} 