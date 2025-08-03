import SwiftUI

struct GlobalToolbar: ToolbarContent {
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var showAddEpic: Bool
    @Binding var showAddProject: Bool
    @Binding var showAddTask: Bool
    @Binding var selectedTask: XTask?

    var body: some ToolbarContent {
        // 主导航工具栏组
        ToolbarItemGroup(placement: .navigation) {
            navigationToolbarContent
        }
        
        // 主要操作工具栏组
        ToolbarItemGroup(placement: .primaryAction) {
            quickTasksContent
        }
        
        // 次要操作工具栏组
        ToolbarItemGroup(placement: .secondaryAction) {
            secondaryActionsContent
        }
    }
    
    // 提取复杂的内容为计算属性
    @ViewBuilder
    private var navigationToolbarContent: some View {
        if taskViewModel.topLevelTasks.isEmpty {
            emptyTasksButton
        } else {
            taskListMenu
        }
    }
    
    @ViewBuilder
    private var emptyTasksButton: some View {
        Button(action: { showAddTask = true }) {
            HStack {
                Image(systemName: "plus.circle")
                Text("添加首个任务")
            }
            .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var taskListMenu: some View {
        Menu {
            ForEach(taskViewModel.topLevelTasks) { task in
                taskMenuButton(for: task)
            }
        } label: {
            HStack {
                Image(systemName: "list.bullet")
                Text("任务 (\(taskViewModel.topLevelTasks.count))")
            }
            .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private func taskMenuButton(for task: XTask) -> some View {
        Button(action: { selectedTask = task }) {
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                Text(task.title)
                Spacer()
                if task.isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    @ViewBuilder
    private var quickTasksContent: some View {
        ForEach(Array(taskViewModel.topLevelTasks.prefix(3).enumerated()), id: \.element.id) { index, task in
            quickTaskButton(for: task, at: index)
        }
    }
    
    @ViewBuilder
    private func quickTaskButton(for task: XTask, at index: Int) -> some View {
        Button(action: { selectedTask = task }) {
            VStack(spacing: 2) {
                Text(task.title)
                    .font(.caption2)
                    .lineLimit(1)
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.caption)
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
        }
    }
    
    @ViewBuilder
    private var secondaryActionsContent: some View {
        Button(action: { showAddEpic = true }) {
            Image(systemName: "flag.circle")
        }
        
        Button(action: { showAddProject = true }) {
            Image(systemName: "folder.circle")
        }
        
        Button(action: { showAddTask = true }) {
            Image(systemName: "plus.circle")
        }
    }
}
