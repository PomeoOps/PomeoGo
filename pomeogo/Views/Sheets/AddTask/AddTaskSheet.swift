import SwiftUI
import Foundation

// AddTaskSheet - 现代化设计
struct AddTaskSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    let project: Project?
    let epic: Epic?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority = .normal
    @State private var status: TaskStatus = .todo
    @State private var dueDate: Date?
    @FocusState private var titleFieldFocused: Bool
    
    init(viewModel: TaskViewModel, project: Project? = nil, epic: Epic? = nil) {
        self.viewModel = viewModel
        self.project = project
        self.epic = epic
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 任务标题卡片
                    taskTitleCard
                    
                    // 描述卡片
                    descriptionCard
                    
                    // 优先级卡片
                    priorityCard
                    
                    // 状态卡片
                    statusCard
                    
                    // 日期卡片
                    dateCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(groupBgColor)
            .navigationTitle("新建任务")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { 
                        dismiss() 
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createTask()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                titleFieldFocused = true
            }
        }
    }
    
    private var taskTitleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("任务标题")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextField("输入任务标题...", text: $title)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(controlBgColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(titleFieldFocused ? .blue : .gray.opacity(0.3), lineWidth: 1)
                )
                .focused($titleFieldFocused)
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.gray)
                    .font(.title2)
                Text("任务描述")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextEditor(text: $description)
                .frame(height: 100)
                .padding(12)
                .background(controlBgColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if description.isEmpty {
                            Text("描述任务的具体要求和目标...")
                                .foregroundColor(.gray)
                                .padding(.horizontal, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("优先级")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priorityOption in
                    TaskPriorityButton(
                        priority: priorityOption,
                        isSelected: priority == priorityOption
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            priority = priorityOption
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "circle.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("状态")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach(TaskStatus.allCases, id: \.self) { statusOption in
                    TaskStatusButton(
                        status: statusOption,
                        isSelected: status == statusOption
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            status = statusOption
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("截止日期")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Toggle(isOn: Binding(
                get: { dueDate != nil },
                set: { if $0 { dueDate = Date() } else { dueDate = nil } }
            )) {
                Label("设置截止日期", systemImage: "calendar")
                    .foregroundColor(.purple)
            }
            .toggleStyle(SwitchToggleStyle(tint: .purple))
            
            if let dueDate = dueDate {
                DatePicker("", selection: Binding(
                    get: { dueDate },
                    set: { self.dueDate = $0 }
                ), displayedComponents: [.date])
                .datePickerStyle(.compact)
                .padding(.leading, 30)
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private func createTask() {
        _Concurrency.Task {
            do {
                let projectId = project?.id
                let epicId = epic?.id
                
                _ = try await viewModel.createTask(
                    title: title,
                    dueDate: dueDate,
                    priority: priority,
                    projectId: projectId
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("创建任务失败: \(error)")
            }
        }
    }
}

