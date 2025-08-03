import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    
    private var todayTasks: [XTask] {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return viewModel.tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate >= startOfDay && dueDate < endOfDay
            }
            return false
        }
    }
    
    var body: some View {
        VStack {
            if todayTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .navigationTitle("今天")
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "今天没有任务",
            systemImage: "calendar",
            description: Text("您今天没有计划的任务。")
        )
    }
    
    private var taskListView: some View {
        List(selection: $selectedTask) {
            ForEach(todayTasks) { task in
                taskRowView(task)
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
    }
    
    private func taskRowView(_ task: XTask) -> some View {
        TaskRowView(task: task)
            .tag(task)
            .swipeActions(edge: .trailing) {
                deleteButton(for: task)
                toggleButton(for: task)
            }
    }
    
    private func deleteButton(for task: XTask) -> some View {
        Button(role: .destructive) {
            Task {
                try? await viewModel.deleteTask(task)
            }
        } label: {
            Image(systemName: "trash")
        }
    }
    
    private func toggleButton(for task: XTask) -> some View {
        Button {
            var updatedTask = task
            updatedTask.toggleCompleted()
            Task {
                try? await viewModel.updateTask(updatedTask)
            }
        } label: {
            Image(systemName: task.isCompleted ? "circle" : "checkmark.circle")
        }
        .tint(task.isCompleted ? .gray : .green)
    }
}

struct ScheduledView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var selectedDate = Date()
    @State private var showingCalendarPicker = true
    
    private var scheduledTasks: [XTask] {
        let start = Calendar.current.startOfDay(for: selectedDate)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return viewModel.tasks.filter { task in
            if let dueDate = task.dueDate {
                return dueDate >= start && dueDate < end
            }
            return false
        }
    }
    
    var body: some View {
        VStack {
            calendarPickerView
            if scheduledTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .navigationTitle("计划")
    }
    
    private var calendarPickerView: some View {
        CalendarPickerView(selectedDate: $selectedDate, showingCalendarPicker: $showingCalendarPicker)
            .frame(height: showingCalendarPicker ? 300 : 60)
            .animation(.easeInOut(duration: 0.3), value: showingCalendarPicker)
            .padding(.bottom, 8)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "此日期没有任务",
            systemImage: "calendar.badge.clock",
            description: Text("\(selectedDate, style: .date) 没有计划的任务。")
        )
    }
    
    private var taskListView: some View {
        List(selection: $selectedTask) {
            ForEach(scheduledTasks) { task in
                taskRowView(task)
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
    }
    
    private func taskRowView(_ task: XTask) -> some View {
        TaskRowView(task: task)
            .tag(task)
            .swipeActions(edge: .trailing) {
                deleteButton(for: task)
                toggleButton(for: task)
            }
    }
    
    private func deleteButton(for task: XTask) -> some View {
        Button(role: .destructive) {
            Task {
                try? await viewModel.deleteTask(task)
            }
        } label: {
            Image(systemName: "trash")
        }
    }
    
    private func toggleButton(for task: XTask) -> some View {
        Button {
            var updatedTask = task
            updatedTask.toggleCompleted()
            Task {
                try? await viewModel.updateTask(updatedTask)
            }
        } label: {
            Image(systemName: task.isCompleted ? "circle" : "checkmark.circle")
        }
        .tint(task.isCompleted ? .gray : .green)
    }
}

struct FlaggedView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    
    private var flaggedTasks: [XTask] {
        return viewModel.tasks.filter { task in
            task.priority == .high || task.priority == .urgent
        }
    }
    
    var body: some View {
        VStack {
            if flaggedTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .navigationTitle("标记")
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "没有标记的任务",
            systemImage: "flag",
            description: Text("您没有高优先级或紧急的任务。")
        )
    }
    
    private var taskListView: some View {
        List(selection: $selectedTask) {
            ForEach(flaggedTasks) { task in
                taskRowView(task)
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
    }
    
    private func taskRowView(_ task: XTask) -> some View {
        TaskRowView(task: task)
            .tag(task)
            .swipeActions(edge: .trailing) {
                deleteButton(for: task)
                toggleButton(for: task)
            }
    }
    
    private func deleteButton(for task: XTask) -> some View {
        Button(role: .destructive) {
            Task {
                try? await viewModel.deleteTask(task)
            }
        } label: {
            Image(systemName: "trash")
        }
    }
    
    private func toggleButton(for task: XTask) -> some View {
        Button {
            var updatedTask = task
            updatedTask.toggleCompleted()
            Task {
                try? await viewModel.updateTask(updatedTask)
            }
        } label: {
            Image(systemName: task.isCompleted ? "circle" : "checkmark.circle")
        }
        .tint(task.isCompleted ? .gray : .green)
    }
}

struct CompletedView: View {
    @ObservedObject var viewModel: TaskViewModel
    @Binding var selectedTask: XTask?
    @State private var groupByDate = true
    
    private var completedTasks: [XTask] {
        return viewModel.tasks.filter { $0.isCompleted }
    }
    
    private var tasksByDate: [Date: [XTask]] {
        Dictionary(grouping: completedTasks) { task in
            Calendar.current.startOfDay(for: task.completedAt ?? Date())
        }
    }
    
    var body: some View {
        VStack {
            if completedTasks.isEmpty {
                emptyStateView
            } else {
                taskListView
            }
        }
        .navigationTitle("已完成")
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "没有已完成的任务",
            systemImage: "checkmark.circle",
            description: Text("当您完成任务时，它们将在这里显示。")
        )
    }
    
    private var taskListView: some View {
        List(selection: $selectedTask) {
            toggleView
            if groupByDate {
                groupedTasksView
            } else {
                simpleTasksView
            }
        }
        .refreshable {
            await viewModel.loadTasks()
        }
    }
    
    private var toggleView: some View {
        Toggle("按日期分组", isOn: $groupByDate)
            .padding(.horizontal)
    }
    
    private var groupedTasksView: some View {
        ForEach(tasksByDate.keys.sorted(by: >), id: \.self) { date in
            Section(header: Text(dateFormatter.string(from: date))) {
                ForEach(tasksByDate[date] ?? []) { task in
                    TaskRowView(task: task)
                        .tag(task)
                }
            }
        }
    }
    
    private var simpleTasksView: some View {
        ForEach(completedTasks.sorted(by: { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) })) { task in
            TaskRowView(task: task)
                .tag(task)
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    NavigationView {
        TodayView(viewModel: TaskViewModel(dataManager: DataManager.shared), selectedTask: .constant(XTask(title: "示例任务")))
    }
} 