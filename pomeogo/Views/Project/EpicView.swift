import SwiftUI

struct EpicView: View {
    var epic: Epic
    @ObservedObject var viewModel: ProjectViewModel
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var showAddTask = false
    @State private var showAddProject = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 16) {
            epicHeaderView
            epicTabView
        }
        .navigationTitle("EPIC: " + epic.name)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(action: { showAddProject = true }) {
                        Label("添加项目", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showAddTask = true }) {
                        Label("添加任务", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(viewModel: taskViewModel, epic: epic)
        }
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectViewModel: viewModel, selectedEpic: epic)
        }
    }
    
    private var epicHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(epic.name)
                    .font(.title)
                    .bold()
                Spacer()
                Menu {
                    Button(action: { showAddProject = true }) {
                        Label("添加项目", systemImage: "folder.badge.plus")
                    }
                    Button(action: { showAddTask = true }) {
                        Label("添加任务", systemImage: "plus")
                    }
                    Divider()
                    Button(action: {
                        // TODO: 编辑EPIC
                    }) {
                        Label("编辑EPIC", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {
                        // TODO: 删除EPIC
                    }) {
                        Label("删除EPIC", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
            
            if !epic.description.isEmpty {
                Text(epic.description)
                    .foregroundColor(.secondary)
            }
            
            // EPIC状态
            HStack {
                Text(epic.isArchived ? "已归档" : "活跃")
                    .font(.caption)
                    .foregroundColor(epic.isArchived ? .orange : .green)
                Spacer()
            }
        }
        .padding()
        .background(groupBgColor)
    }
    
    private var epicTabView: some View {
        VStack {
            Picker("视图", selection: $selectedTab) {
                Text("项目").tag(0)
                Text("任务").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            TabView(selection: $selectedTab) {
                EpicProjectsList(epic: epic, viewModel: viewModel)
                    .tag(0)
                
                EpicTasksList(epic: epic, taskViewModel: taskViewModel, selectedTask: $selectedTask)
                    .tag(1)
            }
        }
    }
}

#Preview {
    EpicView(
        epic: Epic(name: "示例EPIC"),
        viewModel: ProjectViewModel(),
        taskViewModel: TaskViewModel(dataManager: DataManager.shared),
        selectedTask: .constant(nil)
    )
} 