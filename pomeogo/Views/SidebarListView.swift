import SwiftUI

enum SidebarItem: Identifiable, Hashable, Codable {
    case epic(UUID)
    case project(UUID)
    case subTask(UUID)
    
    var id: String {
        switch self {
        case .epic(let id): return "epic-" + id.uuidString
        case .project(let id): return "project-" + id.uuidString
        case .subTask(let id): return "subTask-" + id.uuidString
        }
    }
}

// 1. 拖拽类型声明
private enum SidebarDragType: String { case epic, project, task }

// 2. SidebarItem支持NSItemProvider
extension SidebarItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: SidebarItem.self, contentType: .data)
    }
}

struct SidebarListView: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    var epicViewModels: [EpicViewModel] = []
    @ObservedObject var subTaskViewModel: TaskViewModel
    @Binding var selectedItem: SidebarItem?
    @State private var expandedEpics: Set<String> = []
    @State private var expandedProjects: Set<String> = []
    @State private var expandedTasks: Set<String> = []
    
    // 提取复杂的计算属性
    private var topLevelProjects: [Project] {
        projectViewModel.projects.filter { $0.epicId == nil }
    }
    
    private var topLevelTasks: [XTask] {
        subTaskViewModel.tasks.filter { $0.projectId == nil && $0.epicId == nil && $0.parentId == nil }
    }
    
    var body: some View {
        List(selection: $selectedItem) {
            // 顶层项目部分
            projectsSection
            
            // EPIC部分
            epicsSection
            
            // 顶层任务部分
            tasksSection
        }
        .listStyle(.sidebar)
        .navigationTitle("管理")
    }
    
    // 将复杂的Section提取为单独的视图
    @ViewBuilder
    private var projectsSection: some View {
        if !topLevelProjects.isEmpty {
            Section(header: Text("项目")) {
                ForEach(topLevelProjects) { project in
                    NavigationLink(value: SidebarItem.project(project.id)) {
                        Label(project.name, systemImage: "folder.fill")
                    }
                }
            }
        }
    }
    
    @ViewBuilder  
    private var epicsSection: some View {
        // 暂时移除EPIC部分，因为epicViewModels的epic属性是private的
        EmptyView()
    }
    
    @ViewBuilder
    private var tasksSection: some View {
        if !topLevelTasks.isEmpty {
            Section(header: Text("任务")) {
                ForEach(topLevelTasks) { task in
                    taskRowView(task)
                }
            }
        }
    }
    
    @ViewBuilder
    private func taskRowView(_ task: XTask) -> some View {
        NavigationLink(value: SidebarItem.subTask(task.id)) {
            Label {
                Text(task.title)
                    .strikethrough(task.isCompleted)
            } icon: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
        }
    }
}

// ProjectDisclosure: 支持 Project 下展开 Task
struct ProjectDisclosure: View {
    let project: Project
    @Binding var selectedItem: SidebarItem?
    @Binding var expandedProjects: Set<String>
    @Binding var expandedTasks: Set<String>
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedProjects.contains(project.id.uuidString) },
                set: { expanded in
                    if expanded {
                        expandedProjects.insert(project.id.uuidString)
                    } else {
                        expandedProjects.remove(project.id.uuidString)
                    }
                }
            ),
            content: {
                // 暂时移除项目任务显示，因为Project模型没有tasks属性
                Text("项目任务")
                    .foregroundColor(.secondary)
            },
            label: {
                NavigationLink(value: SidebarItem.project(project.id)) {
                    Label(project.name, systemImage: "folder.fill")
                }
                .onDrag {
                    let item = SidebarItem.project(project.id)
                    let data = try! JSONEncoder().encode(item)
                    let str = String(data: data, encoding: .utf8) ?? ""
                    return NSItemProvider(object: NSString(string: str))
                }
            }
        )
    }
}

// TaskDisclosure: 支持 Task 下递归展开子 Task
struct TaskDisclosure: View {
    let subTask: XTask
    @Binding var selectedItem: SidebarItem?
    @Binding var expandedTasks: Set<String>
    var body: some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedTasks.contains(subTask.id.uuidString) },
                set: { expanded in
                    if expanded {
                        expandedTasks.insert(subTask.id.uuidString)
                    } else {
                        expandedTasks.remove(subTask.id.uuidString)
                    }
                }
            ),
            content: {
                // 暂时移除子任务显示，因为Task模型没有dependencies属性
                Text("子任务")
                    .foregroundColor(.secondary)
            },
            label: {
                NavigationLink(value: SidebarItem.subTask(subTask.id)) {
                    Label(subTask.title, systemImage: subTask.isCompleted ? "checkmark.circle.fill" : "circle")
                }
                .onDrag {
                    let item = SidebarItem.subTask(subTask.id)
                    let data = try! JSONEncoder().encode(item)
                    let str = String(data: data, encoding: .utf8) ?? ""
                    return NSItemProvider(object: NSString(string: str))
                }
            }
        )
    }
} 
