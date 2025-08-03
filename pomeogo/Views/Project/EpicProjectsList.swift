import SwiftUI

struct EpicProjectsList: View {
    let epic: Epic
    @ObservedObject var viewModel: ProjectViewModel
    @State private var projects: [Project] = []
    
    var body: some View {
        List {
            ForEach(projects) { project in
                NavigationLink {
                    ProjectView(
                        project: project, 
                        viewModel: viewModel, 
                        taskViewModel: TaskViewModel(dataManager: DataManager.shared), 
                        selectedTask: .constant(nil)
                    )
                } label: {
                    ProjectRowView(project: project)
                }
            }
        }
        .onAppear {
            loadProjects()
        }
    }
    
    private func loadProjects() {
        _Concurrency.Task {
            do {
                // 这里需要实现根据epic加载项目的逻辑
                // 暂时使用空数组
                await MainActor.run {
                    self.projects = []
                }
            } catch {
                print("加载项目失败: \(error)")
            }
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.name)
                .font(.headline)
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            HStack {
                Text("0% 完成")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("0 任务")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EpicProjectsList(
        epic: Epic(name: "示例EPIC"),
        viewModel: ProjectViewModel()
    )
} 