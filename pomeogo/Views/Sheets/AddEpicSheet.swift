import SwiftUI
import Foundation

// AddEpicSheet - 现代化设计
struct AddEpicSheet: View {
    @ObservedObject var projectViewModel: ProjectViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var color: Color = .blue
    @State private var priority: EpicPriority = .normal
    @FocusState private var nameFieldFocused: Bool
    
    enum EpicPriority: String, CaseIterable {
        case low = "低"
        case normal = "普通"
        case high = "高"
        case critical = "关键"
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .normal: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "minus.circle"
            case .normal: return "circle"
            case .high: return "exclamationmark.circle"
            case .critical: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    epicNameCard
                    descriptionCard
                    priorityCard
                    colorCard
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(groupBgColor)
            .navigationTitle("新建EPIC")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createEpic()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                nameFieldFocused = true
            }
        }
    }
    
    private var epicNameCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flag.circle.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("EPIC名称")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextField("输入EPIC名称...", text: $name)
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
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.gray)
                    .font(.title2)
                Text("描述")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(12)
                    .background(controlBgColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                
                if description.isEmpty {
                    Text("描述EPIC的目标和范围...")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .allowsHitTesting(false)
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private var priorityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                Text("优先级")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach(EpicPriority.allCases, id: \.self) { priorityOption in
                    EpicPriorityButton(
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
    
    private var colorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintbrush.fill")
                    .foregroundColor(.pink)
                    .font(.title2)
                Text("主题色")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 12) {
                ForEach([Color.blue, .purple, .green, .orange, .red, .pink], id: \.self) { colorOption in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            color = colorOption
                        }
                    }) {
                        Circle()
                            .fill(colorOption)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: color == colorOption ? 3 : 0)
                            )
                            .scaleEffect(color == colorOption ? 1.1 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(unemphasizedSelectedContentBgColor)
        .cornerRadius(16)
    }
    
    private func createEpic() {
        _Concurrency.Task {
            do {
                _ = try await projectViewModel.createEpic(name: name, description: description.isEmpty ? nil : description)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("创建史诗失败: \(error)")
            }
        }
    }
}

struct EpicPriorityButton: View {
    let priority: AddEpicSheet.EpicPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: priority.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : priority.color)
                
                Text(priority.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : priority.color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? priority.color : priority.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priority.color, lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 