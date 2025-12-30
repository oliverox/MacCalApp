import EventKit
import SwiftUI

@Observable
class CalendarEventManager {
    static let shared = CalendarEventManager()

    private let eventStore = EKEventStore()
    var authorizationStatus: EKAuthorizationStatus = .notDetermined
    var events: [EKEvent] = []
    var isLoading = false
    var errorMessage: String?

    private init() {
        updateAuthorizationStatus()
    }

    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                updateAuthorizationStatus()
            }
            return granted
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                updateAuthorizationStatus()
            }
            return false
        }
    }

    func fetchEvents(for date: Date) async {
        guard authorizationStatus == .fullAccess else {
            await MainActor.run {
                events = []
            }
            return
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let fetchedEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        await MainActor.run {
            withAnimation(.none) {
                events = fetchedEvents
            }
        }
    }

    func calendarColor(for event: EKEvent) -> Color {
        if let cgColor = event.calendar.cgColor {
            return Color(cgColor: cgColor)
        }
        return .accentColor
    }

    func formatEventTime(_ event: EKEvent) -> String {
        if event.isAllDay {
            return "All day"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)

        return "\(start) - \(end)"
    }
}
