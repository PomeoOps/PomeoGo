import SwiftUI
import Foundation

struct MainSplitView: View {
    @EnvironmentObject private var dataManager: DataManager
    @StateObject private var taskViewModel: TaskViewModel
    @StateObject private var projectViewModel: ProjectViewModel
    @State private var selectedSidebarItem: SidebarItem?
    @State private var selectedTask: XTask?
    
    // 添加弹窗状态变量
    @State private var showAddTask = false
    @State private var showAddEpic = false
    @State private var showAddProject = false
    
    init(dataManager: DataManager) {
        self._taskViewModel = StateObject(wrappedValue: TaskViewModel(dataManager: dataManager))
        self._projectViewModel = StateObject(wrappedValue: ProjectViewModel(dataManager: dataManager))
    }
    
    enum SidebarItem: Hashable {
        case today
        case scheduled
        case all
        case flagged
        case completed
        case project(Project)
        case epic(Epic)
        case task
        
        var title: String {
            switch self {
            case .today: return "今天"
            case .scheduled: return "计划"
            case .all: return "全部"
            case .flagged: return "标记"
            case .completed: return "已完成"
            case .project(let project): return project.name
            case .epic(let epic): return epic.name
            case .task: return "任务"
            }
        }
        
        var icon: String {
            switch self {
            case .today: return "calendar"
            case .scheduled: return "calendar.badge.clock"
            case .all: return "tray.fill"
            case .flagged: return "flag.fill"
            case .completed: return "checkmark.circle.fill"
            case .project: return "folder.fill"
            case .epic: return "star.fill"
            case .task: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // 第一栏：侧边栏导航
            sidebarContent
        } content: {
            // 第二栏：列表内容
            listContent
        } detail: {
            // 第三栏：详细信息
            detailContent
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskSheet(viewModel: taskViewModel)
        }
        .sheet(isPresented: $showAddEpic) {
            AddEpicSheet(projectViewModel: projectViewModel)
        }
        .sheet(isPresented: $showAddProject) {
            AddProjectSheet(projectViewModel: projectViewModel)
        }
    }
    
    private var sidebarContent: some View {
        List(selection: $selectedSidebarItem) {
            smartListSection
            epicSection
            projectSection
            taskSection
        }
        .listStyle(.sidebar)
        .navigationTitle("PomeoGo")
        .toolbar {
            GlobalToolbar(
                taskViewModel: taskViewModel,
                showAddEpic: $showAddEpic,
                showAddProject: $showAddProject,
                showAddTask: $showAddTask,
                selectedTask: $selectedTask
            )
        }
    }
    
    private var listContent: some View {
        NavigationStack {
            Group {
                if let selectedItem = selectedSidebarItem {
                    selectedListView(for: selectedItem)
                } else {
                    // 默认显示全部任务列表
                    TaskListView(viewModel: taskViewModel, selectedTask: $selectedTask)
                }
            }
        }
    }
    
    private var detailContent: some View {
        Group {
            if let task = selectedTask {
                TaskDetailPanelView(task: task, viewModel: taskViewModel)
            } else {
                // 默认显示欢迎页面
                welcomeView
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("选择任务查看详情")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("从左侧选择一个任务来查看和编辑详细信息")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(controlBgColor)
    }
    
    private var smartListSection: some View {
        Section("智能列表") {
            NavigationLink(value: SidebarItem.today) {
                Label("今天", systemImage: "calendar")
            }
            NavigationLink(value: SidebarItem.scheduled) {
                Label("计划", systemImage: "calendar.badge.clock")
            }
            NavigationLink(value: SidebarItem.all) {
                Label("全部", systemImage: "tray.fill")
            }
            NavigationLink(value: SidebarItem.flagged) {
                Label("标记", systemImage: "flag.fill")
            }
            NavigationLink(value: SidebarItem.completed) {
                Label("已完成", systemImage: "checkmark.circle.fill")
            }
        }
    }
    
    private var epicSection: some View {
        Section("EPIC") {
            ForEach(projectViewModel.epics) { epic in
                NavigationLink(value: SidebarItem.epic(epic)) {
                    Label(epic.name, systemImage: "star.fill")
                }
            }
        }
    }
    
    private var projectSection: some View {
        Section("项目") {
            ForEach(projectViewModel.projects) { project in
                NavigationLink(value: SidebarItem.project(project)) {
                    Label(project.name, systemImage: "folder.fill")
                }
            }
        }
    }
    
    private var taskSection: some View {
        Section("任务") {
            NavigationLink(value: SidebarItem.task) {
                Label("任务", systemImage: "list.bullet")
            }
        }
    }
    
    @ViewBuilder
    private func selectedListView(for item: SidebarItem) -> some View {
        switch item {
        case .all:
            TaskListView(viewModel: taskViewModel, selectedTask: $selectedTask)
        case .today:
            TodayView(viewModel: taskViewModel, selectedTask: $selectedTask)
        case .scheduled:
            ScheduledView(viewModel: taskViewModel, selectedTask: $selectedTask)
        case .flagged:
            FlaggedView(viewModel: taskViewModel, selectedTask: $selectedTask)
        case .completed:
            CompletedView(viewModel: taskViewModel, selectedTask: $selectedTask)
        case .project(let project):
            ProjectView(project: project, viewModel: projectViewModel, taskViewModel: taskViewModel, selectedTask: $selectedTask)
        case .epic(let epic):
            EpicView(epic: epic, viewModel: projectViewModel, taskViewModel: taskViewModel, selectedTask: $selectedTask)
        case .task:
            TaskListView(viewModel: taskViewModel, selectedTask: $selectedTask)
        }
    }
}

#Preview {
    MainSplitView(dataManager: DataManager.shared)
}
