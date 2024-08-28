import Foundation
import SwiftUI

struct DayStatus: Identifiable {
    let id = UUID()
    let dayOfWeek: String
    var isCompleted: Bool
    var isCurrent: Bool
}

class WeekStreakViewModel: ObservableObject {
    @Published var days: [DayStatus]
    
    init() {
        let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
        let currentDay = Calendar.current.component(.weekday, from: Date()) - 1
        self.days = daysOfWeek.enumerated().map { index, day in
            DayStatus(dayOfWeek: day, isCompleted: false, isCurrent: index == currentDay)
        }
    }
    
    func toggleDay(_ index: Int) {
        days[index].isCompleted.toggle()
    }
}

struct WeekStreakView: View {
    @ObservedObject var viewModel: WeekStreakViewModel
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(viewModel.days.indices, id: \.self) { index in
                DayCircleView(day: $viewModel.days[index], action: {
                    viewModel.toggleDay(index)
                })
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct DayCircleView: View {
    @Binding var day: DayStatus
    var action: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(day.isCurrent ? Color.blue : Color.gray, lineWidth: 2)
                .frame(width: 40, height: 40)
                .background(Circle().fill(day.isCurrent ? Color.blue.opacity(0.1) : Color.clear)) // 让当前日期的背景更明显
            
            VStack {
                Text(day.dayOfWeek)
                    .font(.system(size: 16, weight: .bold)) // 增大字体大小和加粗
                    .foregroundColor(day.isCurrent ? .blue : .black) // 当前日期字体使用蓝色，其他使用黑色
                
                if day.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold)) // 增大checkmark的大小
                        .foregroundColor(.green)
                }
            }
        }
        .onTapGesture(perform: action)
    }
}

