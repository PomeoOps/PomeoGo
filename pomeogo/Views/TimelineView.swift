import SwiftUI

struct TimelineView: View {
    @ObservedObject var viewModel: TimelineViewModel
    @State private var selectedDate = Date()
    @State private var showingCalendarPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 大尺寸日历控件
                CalendarPickerView(selectedDate: $selectedDate, showingCalendarPicker: $showingCalendarPicker)
                    .frame(height: showingCalendarPicker ? 300 : 60)
                    .animation(.easeInOut(duration: 0.3), value: showingCalendarPicker)
                
                Divider()
                
                // 任务列表
                List {
                    if !viewModel.todayTasks.isEmpty {
                        Section(header: Text("今天")) {
                            ForEach(viewModel.todayTasks) { subTask in
                                TaskRow(subTask: subTask)
                            }
                        }
                    }
                    if !viewModel.upcomingTasks.isEmpty {
                        Section(header: Text("未来")) {
                            ForEach(viewModel.upcomingTasks) { subTask in
                                TaskRow(subTask: subTask)
                            }
                        }
                    }
                    if !viewModel.unscheduledTasks.isEmpty {
                        Section(header: Text("未排期")) {
                            ForEach(viewModel.unscheduledTasks) { subTask in
                                TaskRow(subTask: subTask)
                            }
                        }
                    }
                }
                .listStyle(.automatic)
            }
            .navigationTitle("时间轴")
            .toolbar(content: {
                ToolbarItem(placement: .automatic) {
                    Button(action: viewModel.addTask) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: { showingCalendarPicker.toggle() }) {
                        Image(systemName: showingCalendarPicker ? "calendar.badge.minus" : "calendar.badge.plus")
                    }
                }
            })
        }
    }
}

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var showingCalendarPicker: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部日期显示和切换按钮
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(.dateTime.year().month(.wide)))
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingCalendarPicker.toggle() }) {
                    Image(systemName: showingCalendarPicker ? "chevron.up" : "chevron.down")
                        .foregroundColor(.blue)
                        .font(.headline)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(controlBgColor)
            
            // 展开的日历控件
            if showingCalendarPicker {
                CalendarGridView(selectedDate: $selectedDate)
                    .padding()
                    .background(controlBgColor)
            }
        }
    }
}

struct CalendarGridView: View {
    @Binding var selectedDate: Date
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // 月份导航
            HStack {
                Button(action: { changeMonth(-1) }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(currentMonth.formatted(.dateTime.year().month(.wide)))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { changeMonth(1) }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            
            // 星期标题
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(date: date, selectedDate: $selectedDate, currentMonth: currentMonth)
                }
            }
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstDayOfMonth = monthInterval.start
        let firstDayWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        
        var dates: [Date] = []
        
        // 添加上个月的日期以填充网格
        if firstDayWeekday > 0 {
            for i in (1...firstDayWeekday).reversed() {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    dates.append(date)
                }
            }
        }
        
        // 添加当月的日期
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                dates.append(date)
            }
        }
        
        // 添加下个月的日期以填充网格到42个位置（6周 x 7天）
        while dates.count < 42 {
            if let lastDate = dates.last,
               let nextDate = calendar.date(byAdding: .day, value: 1, to: lastDate) {
                dates.append(nextDate)
            } else {
                break
            }
        }
        
        return dates
    }
    
    private func changeMonth(_ direction: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct DayCell: View {
    let date: Date
    @Binding var selectedDate: Date
    let currentMonth: Date
    
    private let calendar = Calendar.current
    
    var body: some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        
        Button(action: { selectedDate = date }) {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(textColor(isSelected: isSelected, isCurrentMonth: isCurrentMonth))
                .frame(width: 32, height: 32)
                .background(backgroundColor(isSelected: isSelected))
                .cornerRadius(16)
                .overlay(
                    isToday && !isSelected ?
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue, lineWidth: 2)
                    : nil
                )
        }
        .buttonStyle(.plain)
    }
    
    private func textColor(isSelected: Bool, isCurrentMonth: Bool) -> Color {
        if !isCurrentMonth {
            return Color.secondary.opacity(0.5)
        } else if isSelected {
            return Color.white
        } else {
            return Color.primary
        }
    }
    
    private func backgroundColor(isSelected: Bool) -> Color {
        if isSelected {
            return Color.blue
        } else {
            return Color.clear
        }
    }
}

struct TaskRow: View {
    let subTask: XTask
    var body: some View {
        HStack {
            Image(systemName: subTask.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(subTask.isCompleted ? .green : .gray)
            VStack(alignment: .leading) {
                Text(subTask.title)
                    .font(.headline)
                if let due = subTask.dueDate {
                    Text("截止：" + due.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    TimelineView(viewModel: TimelineViewModel.preview)
} 