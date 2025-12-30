import SwiftUI

struct WeekdayHeaderView: View {
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

struct CalendarGridView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var today: Date {
        calendar.startOfDay(for: Date())
    }

    private var monthStart: Date {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return calendar.date(from: components) ?? displayedMonth
    }

    private var daysInMonth: [Date?] {
        var days: [Date?] = []

        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return days
        }

        let firstDayWeekday = calendar.component(.weekday, from: monthInterval.start)
        let leadingEmptyDays = firstDayWeekday - calendar.firstWeekday
        let adjustedLeadingDays = leadingEmptyDays < 0 ? leadingEmptyDays + 7 : leadingEmptyDays

        for i in 0..<adjustedLeadingDays {
            if let date = calendar.date(byAdding: .day, value: i - adjustedLeadingDays, to: monthInterval.start) {
                days.append(date)
            }
        }

        let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        for day in 0..<daysInCurrentMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(date)
            }
        }

        let remainingDays = (7 - (days.count % 7)) % 7
        if let lastDay = calendar.date(byAdding: .day, value: daysInCurrentMonth - 1, to: monthInterval.start) {
            for i in 1...max(remainingDays, 1) {
                if remainingDays == 0 { break }
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    days.append(date)
                }
            }
        }

        return days
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: today)
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(daysInMonth.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    DayCell(
                        date: date,
                        isCurrentMonth: isCurrentMonth(date),
                        isToday: isToday(date),
                        isSelected: isSelected(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                } else {
                    Text("")
                        .frame(width: 28, height: 28)
                }
            }
        }
    }
}

struct DayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isToday: Bool
    let isSelected: Bool

    private let calendar = Calendar.current

    var body: some View {
        Text("\(calendar.component(.day, from: date))")
            .font(.system(size: 12))
            .fontWeight(isToday || isSelected ? .bold : .regular)
            .foregroundStyle(foregroundColor)
            .frame(width: 28, height: 28)
            .background(
                Circle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                Circle()
                    .strokeBorder(isToday && !isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return .accentColor
        } else if isCurrentMonth {
            return .primary
        } else {
            return .secondary.opacity(0.5)
        }
    }
}

#Preview {
    CalendarGridView(displayedMonth: .constant(Date()), selectedDate: .constant(Date()))
        .padding()
        .frame(width: 250)
}
