import SwiftUI

struct ProjectTaskList: View {
    var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var projectTasks: [XTask] = []
    
    var body: some View {
        List(selection: $selectedTask) {
            ForEach(projectTasks.sorted { $0.priority.rawValue > $1.priority.rawValue }) { task in
                TaskRowView(task: task)
                    .tag(task)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTask(task)
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
            }
        }
        .refreshable {
            loadProjectTasks()
        }
        .onAppear {
            loadProjectTasks()
        }
    }
    
    private func loadProjectTasks() {
        _Concurrency.Task {
            do {
                // 使用 TaskViewModel 的公共方法加载任务
                await taskViewModel.loadTasks()
                let filteredTasks = taskViewModel.tasks.filter { $0.projectId == project.id }
                await MainActor.run {
                    self.projectTasks = filteredTasks
                }
            } catch {
                print("加载项目任务失败: \(error)")
            }
        }
    }
    
    private func deleteTask(_ task: XTask) {
        _Concurrency.Task {
            do {
                try await taskViewModel.deleteTask(task)
                await loadProjectTasks()
            } catch {
                print("删除任务失败: \(error)")
            }
        }
    }
}

#Preview {
    ProjectTaskList(
        project: Project(name: "示例项目"),
        viewModel: ProjectViewModel(),
        taskViewModel: TaskViewModel(dataManager: DataManager.shared),
        selectedTask: .constant(nil)
    )
} 