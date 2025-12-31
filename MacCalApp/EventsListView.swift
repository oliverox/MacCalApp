import SwiftUI
import EventKit

struct EventsListView: View {
    let selectedDate: Date
    @State private var eventManager = CalendarEventManager.shared

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isToday ? "Today's Events" : "Events")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            switch eventManager.authorizationStatus {
            case .notDetermined:
                RequestAccessView(eventManager: eventManager)

            case .denied, .restricted:
                NoAccessView()

            case .fullAccess, .writeOnly:
                if eventManager.events.isEmpty {
                    Text("No events")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    EventsList(events: eventManager.events, eventManager: eventManager)
                }

            @unknown default:
                Text("Unknown calendar status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.none, value: eventManager.events.count)
        .task(id: selectedDate) {
            await eventManager.fetchEvents(for: selectedDate)
        }
        .onAppear {
            eventManager.updateAuthorizationStatus()
        }
    }
}

struct RequestAccessView: View {
    let eventManager: CalendarEventManager

    var body: some View {
        VStack(spacing: 8) {
            Text("Calendar access needed")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Grant Access") {
                Task {
                    await eventManager.requestAccess()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct NoAccessView: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("Calendar access denied")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Enable in System Settings > Privacy")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct EventsList: View {
    let events: [EKEvent]
    let eventManager: CalendarEventManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(events.prefix(5), id: \.eventIdentifier) { event in
                EventRow(event: event, eventManager: eventManager)
            }

            if events.count > 5 {
                Text("+\(events.count - 5) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 20)
            }
        }
    }
}

struct EventRow: View {
    let event: EKEvent
    let eventManager: CalendarEventManager
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            eventManager.openEventInCalendar(event)
        }) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(eventManager.calendarColor(for: event))
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title ?? "Untitled")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(eventManager.formatEventTime(event))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isHovered ? Color.primary.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    EventsListView(selectedDate: Date())
        .padding()
        .frame(width: 250)
}
