import SwiftUI
import Foundation

// AddProjectSheet - 现代化设计
struct AddProjectSheet: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    let selectedEpic: Epic?
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var epic: Epic?
    @State private var status: String = "planning"
    @State private var dueDate: Date?
    @FocusState private var nameFieldFocused: Bool
    
    init(projectViewModel: ProjectViewModel, selectedEpic: Epic? = nil) {
        self.projectViewModel = projectViewModel
        self.selectedEpic = selectedEpic
        self._epic = State(initialValue: selectedEpic)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 项目名称卡片
                    projectNameCard
                    
                    // EPIC选择卡片
                    epicSelectionCard
                    
                    // 状态卡片
                    statusCard
                    
                    // 截止日期卡片
                    dueDateCard
                    
                    // 描述卡片
                    descriptionCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(groupBgColor)
            .navigationTitle("新建项目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { 
                        dismiss() 
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(width: 600, height: 500) // 减小高度从650到500
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                nameFieldFocused = true
            }
        }
    }
    
    private var projectNameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("项目名称")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextField("输入项目名称...", text: $name)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(controlBgColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(nameFieldFocused ? .blue : .gray.opacity(0.3), lineWidth: 1)
                )
                .focused($nameFieldFocused)
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var epicSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("归属EPIC")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Picker("选择EPIC", selection: $epic) {
                Text("无").tag(Epic?.none)
                ForEach(projectViewModel.epics) { epicOption in
                    Text(epicOption.name).tag(Epic?.some(epicOption))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(controlBgColor)
            .cornerRadius(12)
            .disabled(selectedEpic != nil) // 如果有预选Epic则禁用选择
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("项目状态")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            // 项目状态选择暂时移除，因为Project模型没有状态枚举
            Text("项目状态: 活跃")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var dueDateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.orange)
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
                    .foregroundColor(.orange)
            }
            .toggleStyle(SwitchToggleStyle(tint: .orange))
            
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
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.gray)
                    .font(.title2)
                Text("项目描述")
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
                            Text("描述项目的目标、范围和关键成果...")
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
    
    private func createProject() {
        _Concurrency.Task {
            do {
                _ = try await projectViewModel.createProject(name: name, description: description.isEmpty ? nil : description)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("创建项目失败: \(error)")
            }
        }
    }
}

struct ProjectStatusButton: View {
    let status: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue : .blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.blue, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 