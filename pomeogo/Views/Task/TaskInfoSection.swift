import SwiftUI

struct TaskInfoSection: View {
    @State var task: XTask
    
    var body: some View {
        Section {
            let createdAt = task.createdAt
            let updatedAt = task.updatedAt
            let completedAt = task.completedAt
            
            HStack {
                Text("创建时间")
                Spacer()
                Text(createdAt, style: .date)
                    .foregroundColor(.gray)
            }
            
            HStack {
                Text("更新时间")
                Spacer()
                Text(updatedAt, style: .date)
                    .foregroundColor(.gray)
            }
            
            if let completedAt = completedAt {
                HStack {
                    Text("完成时间")
                    Spacer()
                    Text(completedAt, style: .date)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}

#Preview {
    List {
        TaskInfoSection(task: XTask(title: "示例任务"))
    }
} 