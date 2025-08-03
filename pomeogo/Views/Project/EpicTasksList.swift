import SwiftUI

struct EpicTasksList: View {
    let epic: Epic
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var tasks: [XTask] = []
    
    var body: some View {
        List(selection: $selectedTask) {
            ForEach(tasks) { task in
                TaskRowView(task: task)
                    .tag(task)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            _Concurrency.Task {
                                do {
                                    try await taskViewModel.deleteTask(task)
                                    await loadTasks()
                                } catch {
                                    print("删除任务失败: \(error)")
                                }
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
            }
        }
        .refreshable {
            await loadTasks()
        }
        .task {
            await loadTasks()
        }
    }
    
    private func loadTasks() async {
        do {
            // 使用TaskViewModel的公共方法加载任务
            await taskViewModel.loadTasks()
            tasks = taskViewModel.tasks.filter { $0.epicId == epic.id }
        } catch {
            print("加载史诗任务失败: \(error)")
        }
    }
}

#Preview {
    EpicTasksList(
        epic: Epic(name: "示例EPIC"),
        taskViewModel: TaskViewModel(dataManager: DataManager.shared),
        selectedTask: .constant(nil)
    )
} 