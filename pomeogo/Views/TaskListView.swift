import SwiftUI

struct TaskListView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var isAddingTask = false
    @State private var searchText = ""
    
    // 提取排序后的任务状态组
    private var sortedTaskGroups: [(TaskStatus, [XTask])] {
        viewModel.tasksGroupedByStatus().sorted(by: { $0.key.rawValue < $1.key.rawValue })
    }
    
    var body: some View {
        List(selection: $selectedTask) {
            searchSection
            filterSection
            taskGroupsSection
        }
        .listStyle(.inset)
        .navigationTitle("任务")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addTaskButton
            }
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskSheet(viewModel: viewModel)
        }
    }
    
    // 将复杂的部分提取为独立的视图组件
    @ViewBuilder
    private var searchSection: some View {
        SearchBar(text: $searchText)
            .onChange(of: searchText) { _, newValue in
                viewModel.searchText = newValue
            }
    }
    
    @ViewBuilder
    private var filterSection: some View {
        FilterBar(viewModel: viewModel)
    }
    
    @ViewBuilder
    private var taskGroupsSection: some View {
        ForEach(sortedTaskGroups, id: \.0) { status, tasks in
            taskSection(for: status)
        }
    }
    
    @ViewBuilder
    private func taskSection(for status: TaskStatus) -> some View {
        let filteredTasks = tasksForStatus(status)
        Section(header: TaskSectionHeader(status: status, count: filteredTasks.count)) {
            ForEach(filteredTasks) { task in
                taskRow(task)
            }
        }
    }
    
    private func tasksForStatus(_ status: TaskStatus) -> [XTask] {
        viewModel.topLevelTasks
            .filter { $0.status == status }
            .sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    @ViewBuilder
    private func taskRow(_ task: XTask) -> some View {
        TaskRowView(task: task)
            .tag(task)
            .swipeActions(edge: .trailing) {
                taskSwipeActions(for: task)
            }
    }
    
    @ViewBuilder
    private func taskSwipeActions(for task: XTask) -> some View {
        Button(role: .destructive) {
            _Concurrency.Task {
                do {
                    try await viewModel.deleteTask(task)
                } catch {
                    print("删除任务失败: \(error)")
                }
            }
        } label: {
            Label("删除", systemImage: "trash")
        }
        
        if task.isCompleted {
            Button {
                _Concurrency.Task {
                    do {
                        try await viewModel.reopenTask(task)
                    } catch {
                        print("重新打开任务失败: \(error)")
                    }
                }
            } label: {
                Label("重新打开", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        } else {
            Button {
                _Concurrency.Task {
                    do {
                        try await viewModel.completeTask(task)
                    } catch {
                        print("完成任务失败: \(error)")
                    }
                }
            } label: {
                Label("完成", systemImage: "checkmark")
            }
            .tint(.green)
        }
    }
    
    @ViewBuilder
    private var addTaskButton: some View {
        Button {
            isAddingTask = true
        } label: {
            Image(systemName: "plus")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("搜索任务", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(groupBgColor)
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

struct FilterBar: View {
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 状态过滤器
                Menu {
                    Button("全部状态") {
                        viewModel.selectedStatus = nil
                    }
                    ForEach(TaskStatus.allCases, id: \.self) { status in
                        Button(status.rawValue) {
                            viewModel.selectedStatus = status
                        }
                    }
                } label: {
                    FilterChip(
                        title: viewModel.selectedStatus?.rawValue ?? "状态",
                        isSelected: viewModel.selectedStatus != nil
                    )
                }
                
                // 优先级过滤器
                Menu {
                    Button("全部优先级") {
                        viewModel.selectedPriority = nil
                    }
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Button(priority.title) {
                            viewModel.selectedPriority = priority
                        }
                    }
                } label: {
                    FilterChip(
                        title: viewModel.selectedPriority?.title ?? "优先级",
                        isSelected: viewModel.selectedPriority != nil
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
    }
}

struct TaskSectionHeader: View {
    let status: TaskStatus
    let count: Int
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
            Text(status.rawValue)
            Spacer()
            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        TaskListView(viewModel: TaskViewModel(dataManager: DataManager.shared), selectedTask: .constant(XTask(title: "示例任务")))
    }
} 
