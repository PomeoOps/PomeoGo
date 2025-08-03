import SwiftUI

struct TaskDateSection: View {
    @State var task: XTask
    @ObservedObject var viewModel: TaskViewModel
    
    var body: some View {
        Section {
            // 开始时间
            HStack {
                Label("开始时间", systemImage: "play.circle")
                Spacer()
                if let startDate = task.startDate {
                    DatePicker("", selection: Binding(
                        get: { startDate },
                        set: { 
                            task.startDate = $0
                            _Concurrency.Task {
                                do {
                                    try await viewModel.updateTask(task)
                                } catch {
                                    print("更新任务失败: \(error)")
                                }
                            }
                        }
                    ), displayedComponents: [.date, .hourAndMinute])
                } else {
                    Button("添加开始时间") {
                        task.startDate = Date()
                        _Concurrency.Task {
                            do {
                                try await viewModel.updateTask(task)
                            } catch {
                                print("更新任务失败: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 结束时间
            HStack {
                Label("结束时间", systemImage: "stop.circle")
                Spacer()
                if let endDate = task.endDate {
                    DatePicker("", selection: Binding(
                        get: { endDate },
                        set: { 
                            task.endDate = $0
                            _Concurrency.Task {
                                do {
                                    try await viewModel.updateTask(task)
                                } catch {
                                    print("更新任务失败: \(error)")
                                }
                            }
                        }
                    ), displayedComponents: [.date, .hourAndMinute])
                } else {
                    Button("添加结束时间") {
                        task.endDate = Date()
                        _Concurrency.Task {
                            do {
                                try await viewModel.updateTask(task)
                            } catch {
                                print("更新任务失败: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 截止日期
            HStack {
                Label("截止日期", systemImage: "calendar")
                Spacer()
                if let dueDate = task.dueDate {
                    DatePicker("", selection: Binding(
                        get: { dueDate },
                        set: { 
                            task.dueDate = $0
                            _Concurrency.Task {
                                do {
                                    try await viewModel.updateTask(task)
                                } catch {
                                    print("更新任务失败: \(error)")
                                }
                            }
                        }
                    ), displayedComponents: [.date])
                } else {
                    Button("添加日期") {
                        task.dueDate = Date()
                        _Concurrency.Task {
                            do {
                                try await viewModel.updateTask(task)
                            } catch {
                                print("更新任务失败: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // 提醒时间
            HStack {
                Label("提醒", systemImage: "bell")
                Spacer()
                if let reminderDate = task.reminderDate {
                    DatePicker("", selection: Binding(
                        get: { reminderDate },
                        set: { 
                            task.reminderDate = $0
                            _Concurrency.Task {
                                do {
                                    try await viewModel.updateTask(task)
                                } catch {
                                    print("更新任务失败: \(error)")
                                }
                            }
                        }
                    ), displayedComponents: [.date, .hourAndMinute])
                } else {
                    Button("添加提醒") {
                        task.reminderDate = Date()
                        _Concurrency.Task {
                            do {
                                try await viewModel.updateTask(task)
                            } catch {
                                print("更新任务失败: \(error)")
                            }
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    List {
        TaskDateSection(
            task: XTask(title: "示例任务"),
            viewModel: TaskViewModel(dataManager: DataManager.shared)
        )
    }
} 