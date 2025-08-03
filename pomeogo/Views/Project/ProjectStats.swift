import SwiftUI
import Charts

struct ProjectStats: View {
    let project: Project
    @ObservedObject var viewModel: TaskViewModel
    @State private var projectTasks: [XTask] = []
    
    var tasksByStatus: [TaskStatus: Int] {
        Dictionary(grouping: projectTasks, by: { $0.status })
            .mapValues { $0.count }
    }
    
    var tasksByPriority: [TaskPriority: Int] {
        Dictionary(grouping: projectTasks, by: { $0.priority })
            .mapValues { $0.count }
    }
    
    var body: some View {
        List {
            Section(header: Text("任务状态")) {
                Chart(tasksByStatus.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { item in
                    BarMark(
                        x: .value("数量", item.value),
                        y: .value("状态", item.key.rawValue)
                    )
                }
                .frame(height: 200)
            }
            
            Section(header: Text("任务优先级")) {
                Chart(tasksByPriority.sorted(by: { $0.key.rawValue > $1.key.rawValue }), id: \.key) { item in
                    BarMark(
                        x: .value("数量", item.value),
                        y: .value("优先级", item.key.title)
                    )
                }
                .frame(height: 200)
            }
            
            if !projectTasks.isEmpty {
                Section(header: Text("完成情况")) {
                    let completed = projectTasks.filter { $0.isCompleted }.count
                    let total = projectTasks.count
                    
                    Chart {
                        SectorMark(
                            angle: .value("已完成", completed),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.blue)
                        
                        SectorMark(
                            angle: .value("未完成", total - completed),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(.gray.opacity(0.2))
                    }
                    .frame(height: 200)
                }
            }
        }
        .onAppear {
            loadProjectTasks()
        }
    }
    
    private func loadProjectTasks() {
        _Concurrency.Task {
            do {
                // 使用TaskViewModel的公共方法获取任务
                await viewModel.loadTasks()
                await MainActor.run {
                    self.projectTasks = viewModel.tasks.filter { $0.projectId == project.id }
                }
            } catch {
                print("加载项目任务失败: \(error)")
            }
        }
    }
}

#Preview {
    ProjectStats(
        project: Project(name: "示例项目"),
        viewModel: TaskViewModel(dataManager: DataManager.shared)
    )
} 