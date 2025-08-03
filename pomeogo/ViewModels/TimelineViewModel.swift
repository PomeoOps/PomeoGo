import Foundation
import Combine

class TimelineViewModel: ObservableObject {
    @Published var todayTasks: [XTask] = []
    @Published var upcomingTasks: [XTask] = []
    @Published var unscheduledTasks: [XTask] = []
    
    private var allTasks: [XTask] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(subTasks: [XTask] = []) {
        self.allTasks = subTasks
        groupTasks()
    }
    
    func updateTasks(_ subTasks: [XTask]) {
        self.allTasks = subTasks
        groupTasks()
    }
    
    private func groupTasks() {
        let now = Calendar.current.startOfDay(for: Date())
        todayTasks = allTasks.filter { subTask in
            guard let due = subTask.dueDate else { return false }
            return Calendar.current.isDate(due, inSameDayAs: now)
        }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        upcomingTasks = allTasks.filter { subTask in
            guard let due = subTask.dueDate else { return false }
            return due > now && !Calendar.current.isDate(due, inSameDayAs: now)
        }.sorted { $0.dueDate ?? Date.distantFuture < $1.dueDate ?? Date.distantFuture }
        unscheduledTasks = allTasks.filter { $0.dueDate == nil }
    }
    
    func addTask() {
        // 示例：实际应弹出添加界面
        var newTask = XTask(title: "新任务", dueDate: Date())
        newTask.isCompleted = false
        allTasks.append(newTask)
        groupTasks()
    }
    
    // 预览用
    static var preview: TimelineViewModel {
        let subTasks = [
            XTask(title: "今天任务", dueDate: Date()),
            XTask(title: "未来任务", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())),
            XTask(title: "无日期任务", dueDate: nil)
        ]
        return TimelineViewModel(subTasks: subTasks)
    }
} 