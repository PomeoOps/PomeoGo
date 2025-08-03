import SwiftUI

// 这个文件现在只包含对其他拆分文件的引用
// 主要的Project组件已经被拆分到 Views/Project/ 目录下

#Preview {
    ProjectView(
        project: Project(name: "示例项目"),
        viewModel: ProjectViewModel(),
        taskViewModel: TaskViewModel(dataManager: DataManager.shared),
        selectedTask: .constant(nil)
    )
} 
