import EventKit
import SwiftUI
import AppKit

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

    func openEventInCalendar(_ event: EKEvent) {
        let timestamp = event.startDate.timeIntervalSinceReferenceDate
        if let url = URL(string: "ical://ekevent/\(event.eventIdentifier ?? "")") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback: open Calendar.app to the event's date
            if let calendarURL = URL(string: "calshow:\(timestamp)") {
                NSWorkspace.shared.open(calendarURL)
            }
        }
    }

    // MARK: - Natural Language Event Creation

    struct ParsedEventData {
        let title: String
        let startDate: Date
        let endDate: Date
        let isAllDay: Bool
    }

    enum QuickAddError: LocalizedError {
        case noDateFound
        case calendarAccessDenied
        case noDefaultCalendar
        case saveFailed(Error)
        case invalidInput

        var errorDescription: String? {
            switch self {
            case .noDateFound:
                return "Could not detect a date/time. Try: 'meeting at 3pm tomorrow'"
            case .calendarAccessDenied:
                return "Calendar access required"
            case .noDefaultCalendar:
                return "No default calendar found"
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            case .invalidInput:
                return "Please enter an event description"
            }
        }
    }

    func parseNaturalLanguage(_ input: String, referenceDate: Date) -> ParsedEventData? {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        guard !trimmedInput.isEmpty else { return nil }

        let calendar = Calendar.current
        var title = trimmedInput
        var startHour: Int?
        var startMinute: Int = 0
        var endHour: Int?
        var endMinute: Int = 0

        // Try to match time range patterns like "9-5pm", "9am-5pm", "9:30-5:30pm", "9 to 5pm"
        let timeRangePattern = #"(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:-|to)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)"#
        if let regex = try? NSRegularExpression(pattern: timeRangePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: trimmedInput, options: [], range: NSRange(trimmedInput.startIndex..., in: trimmedInput)) {

            // Extract start hour
            if let startHourRange = Range(match.range(at: 1), in: trimmedInput) {
                startHour = Int(trimmedInput[startHourRange])
            }
            // Extract start minute (optional)
            if let startMinRange = Range(match.range(at: 2), in: trimmedInput) {
                startMinute = Int(trimmedInput[startMinRange]) ?? 0
            }
            // Extract start am/pm (optional)
            var startIsPM = false
            if let startAmPmRange = Range(match.range(at: 3), in: trimmedInput) {
                startIsPM = trimmedInput[startAmPmRange].lowercased() == "pm"
            }
            // Extract end hour
            if let endHourRange = Range(match.range(at: 4), in: trimmedInput) {
                endHour = Int(trimmedInput[endHourRange])
            }
            // Extract end minute (optional)
            if let endMinRange = Range(match.range(at: 5), in: trimmedInput) {
                endMinute = Int(trimmedInput[endMinRange]) ?? 0
            }
            // Extract end am/pm
            var endIsPM = false
            if let endAmPmRange = Range(match.range(at: 6), in: trimmedInput) {
                endIsPM = trimmedInput[endAmPmRange].lowercased() == "pm"
            }

            // If start am/pm not specified, infer from end and logic
            if match.range(at: 3).location == NSNotFound {
                // If end is PM and start hour is less than end hour, start is likely AM
                // But if start hour > end hour (like 9-5pm where 9 > 5), start is AM
                if let sh = startHour, let eh = endHour {
                    if endIsPM && sh > eh {
                        startIsPM = false // 9-5pm means 9am-5pm
                    } else if endIsPM && sh <= eh && sh < 12 {
                        startIsPM = true // 1-5pm means 1pm-5pm
                    }
                }
            }

            // Convert to 24-hour format
            if var sh = startHour {
                if startIsPM && sh < 12 { sh += 12 }
                if !startIsPM && sh == 12 { sh = 0 }
                startHour = sh
            }
            if var eh = endHour {
                if endIsPM && eh < 12 { eh += 12 }
                if !endIsPM && eh == 12 { eh = 0 }
                endHour = eh
            }

            // Remove matched time range from title
            if let matchRange = Range(match.range, in: trimmedInput) {
                title = trimmedInput.replacingCharacters(in: matchRange, with: "")
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "at on for - "))
                    .trimmingCharacters(in: .whitespaces)
            }
        } else {
            // Fall back to NSDataDetector for single time
            if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
                let range = NSRange(trimmedInput.startIndex..., in: trimmedInput)
                let matches = detector.matches(in: trimmedInput, options: [], range: range)

                for match in matches {
                    if let date = match.date,
                       let swiftRange = Range(match.range, in: trimmedInput) {
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: date)
                        if !(timeComponents.hour == 0 && timeComponents.minute == 0) {
                            startHour = timeComponents.hour
                            startMinute = timeComponents.minute ?? 0
                        }
                        title = trimmedInput.replacingCharacters(in: swiftRange, with: "")
                            .trimmingCharacters(in: .whitespaces)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "at on for - "))
                            .trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }
        }

        // If no title extracted, use the original input
        if title.isEmpty {
            title = trimmedInput
        }

        // Build start date using selected date + parsed time
        var startComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        startComponents.hour = startHour ?? 9
        startComponents.minute = startMinute

        let startDate = calendar.date(from: startComponents) ?? referenceDate

        // Build end date
        let endDate: Date
        if let eh = endHour {
            var endComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            endComponents.hour = eh
            endComponents.minute = endMinute
            endDate = calendar.date(from: endComponents) ?? calendar.date(byAdding: .hour, value: 1, to: startDate)!
        } else {
            endDate = calendar.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        }

        return ParsedEventData(
            title: title.isEmpty ? "New Event" : title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: false
        )
    }

    func createEventFromNaturalLanguage(
        _ input: String,
        referenceDate: Date
    ) async -> Result<String, QuickAddError> {
        // Check authorization
        guard authorizationStatus == .fullAccess else {
            return .failure(.calendarAccessDenied)
        }

        // Parse the input
        guard let parsedData = parseNaturalLanguage(input, referenceDate: referenceDate) else {
            return .failure(.invalidInput)
        }

        // Get default calendar
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            return .failure(.noDefaultCalendar)
        }

        // Create the event
        let event = EKEvent(eventStore: eventStore)
        event.title = parsedData.title
        event.startDate = parsedData.startDate
        event.endDate = parsedData.endDate
        event.isAllDay = parsedData.isAllDay
        event.calendar = defaultCalendar

        // Save the event
        do {
            try eventStore.save(event, span: .thisEvent)
            return .success(parsedData.title)
        } catch {
            return .failure(.saveFailed(error))
        }
    }
}
