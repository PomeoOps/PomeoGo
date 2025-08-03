import SwiftUI

struct ProjectView: View {
    var project: Project
    @ObservedObject var viewModel: ProjectViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var showAddTask = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 项目头部信息
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(project.name)
                        .font(.title)
                        .bold()
                    Spacer()
                    Menu {
                        Button(action: { showAddTask = true }) {
                            Label("添加任务", systemImage: "plus")
                        }
                        Button(action: {
                            // TODO: 编辑项目
                        }) {
                            Label("编辑项目", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: {
                            // TODO: 删除项目
                        }) {
                            Label("删除项目", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
                
                if !project.description.isEmpty {
                    Text(project.description)
                        .foregroundColor(.secondary)
                }
                
                // 项目状态
                HStack {
                    Text(project.isArchived ? "已归档" : "活跃")
                        .font(.caption)
                        .foregroundColor(project.isArchived ? .orange : .green)
                    Spacer()
                }
            }
            .padding()
            .background(groupBgColor)
            
            // 分段控制器
            Picker("视图", selection: $selectedTab) {
                Text("列表").tag(0)
                Text("统计").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            // 内容视图
            TabView(selection: $selectedTab) {
                // 列表视图
                ProjectTaskList(project: project, viewModel: viewModel, taskViewModel: taskViewModel, selectedTask: $selectedTask)
                    .tag(0)
                
                // 统计视图
                ProjectStats(project: project, viewModel: taskViewModel)
                    .tag(1)
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(viewModel: taskViewModel, project: project)
        }
    }
}

#Preview {
    ProjectView(
        project: Project(name: "示例项目", description: ""),
        viewModel: ProjectViewModel(),
        taskViewModel: TaskViewModel(dataManager: DataManager.shared),
        selectedTask: .constant(nil as XTask?)
    )
} 