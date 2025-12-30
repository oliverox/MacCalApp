import SwiftUI
import AppKit

struct CalendarPopoverView: View {
    @State private var displayedMonth = Date()
    @State private var selectedDate = Date()
    @State private var slideOffset: CGFloat = 0
    @State private var previousMonth_: Date = Date()
    @State private var isAnimating = false
    @Environment(\.openWindow) private var openWindow

    private let calendar = Calendar.current
    private let calendarWidth: CGFloat = 218

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: goToPreviousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Previous month")
                .disabled(isAnimating)

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: goToNextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Next month")
                .disabled(isAnimating)
            }

            VStack(spacing: 8) {
                WeekdayHeaderView()

                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        CalendarGridView(displayedMonth: .constant(previousMonth_), selectedDate: $selectedDate)
                            .frame(width: geometry.size.width)

                        CalendarGridView(displayedMonth: $displayedMonth, selectedDate: $selectedDate)
                            .frame(width: geometry.size.width)
                    }
                    .offset(x: slideOffset)
                }
                .frame(height: 192)
                .clipped()
            }

            Divider()

            EventsListView(selectedDate: selectedDate)

            Divider()

            HStack {
                Button(action: goToToday) {
                    Text("Today")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button(action: openSettings) {
                    Image(systemName: "gear")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Settings")
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            previousMonth_ = displayedMonth
            slideOffset = -calendarWidth
        }
    }

    private func goToPreviousMonth() {
        guard !isAnimating else { return }
        guard let newDate = calendar.date(byAdding: .month, value: -1, to: displayedMonth) else { return }

        isAnimating = true
        previousMonth_ = newDate
        slideOffset = -calendarWidth

        withAnimation(.easeInOut(duration: 0.35)) {
            slideOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            displayedMonth = newDate
            slideOffset = -calendarWidth
            isAnimating = false
        }
    }

    private func goToNextMonth() {
        guard !isAnimating else { return }
        guard let newDate = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return }

        isAnimating = true
        previousMonth_ = displayedMonth
        displayedMonth = newDate
        slideOffset = 0

        withAnimation(.easeInOut(duration: 0.35)) {
            slideOffset = -calendarWidth
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isAnimating = false
        }
    }

    private func goToToday() {
        guard !isAnimating else { return }
        let today = Date()

        if calendar.isDate(displayedMonth, equalTo: today, toGranularity: .month) {
            selectedDate = today
            return
        }

        let goingForward = calendar.compare(displayedMonth, to: today, toGranularity: .month) == .orderedAscending

        isAnimating = true

        if goingForward {
            previousMonth_ = displayedMonth
            displayedMonth = today
            slideOffset = 0

            withAnimation(.easeInOut(duration: 0.35)) {
                slideOffset = -calendarWidth
            }
        } else {
            previousMonth_ = today
            slideOffset = -calendarWidth

            withAnimation(.easeInOut(duration: 0.35)) {
                slideOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                displayedMonth = today
                slideOffset = -calendarWidth
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            selectedDate = today
            isAnimating = false
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: "settings")
    }
}

#Preview {
    CalendarPopoverView()
}
