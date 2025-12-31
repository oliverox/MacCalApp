import SwiftUI
import EventKit

struct EventsListView: View {
    let selectedDate: Date
    var refreshTrigger: Int = 0
    var onEventCreated: (() -> Void)? = nil

    @State private var eventManager = CalendarEventManager.shared
    @State private var isAddingEvent = false
    @State private var inputText = ""
    @State private var feedbackState: FeedbackState = .idle
    @State private var feedbackMessage = ""
    @FocusState private var isInputFocused: Bool

    enum FeedbackState {
        case idle, parsing, success, error
    }

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
            // Header with + button
            HStack {
                Text(isToday ? "Today's Events" : "Events")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                if eventManager.authorizationStatus == .fullAccess {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isAddingEvent.toggle()
                            if isAddingEvent {
                                isInputFocused = true
                            } else {
                                inputText = ""
                                feedbackMessage = ""
                                feedbackState = .idle
                                isInputFocused = false
                            }
                        }
                    }) {
                        Image(systemName: isAddingEvent ? "xmark.circle" : "plus.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(isAddingEvent ? "Cancel" : "Add event")
                }
            }

            // Expandable quick add input
            if isAddingEvent {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        TextField("e.g., movie at 7pm", text: $inputText)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .focused($isInputFocused)
                            .onSubmit { submitEvent() }
                            .disabled(feedbackState == .parsing)

                        if feedbackState == .parsing {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 12, height: 12)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: 1)
                    )

                    if !feedbackMessage.isEmpty {
                        Text(feedbackMessage)
                            .font(.caption2)
                            .foregroundStyle(feedbackState == .error ? .red : .green)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

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
        .task(id: "\(selectedDate)-\(refreshTrigger)") {
            await eventManager.fetchEvents(for: selectedDate)
        }
        .onAppear {
            eventManager.updateAuthorizationStatus()
        }
    }

    private var borderColor: Color {
        switch feedbackState {
        case .idle: return Color.primary.opacity(0.1)
        case .parsing: return Color.accentColor.opacity(0.5)
        case .success: return Color.green.opacity(0.5)
        case .error: return Color.red.opacity(0.5)
        }
    }

    private func submitEvent() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        feedbackState = .parsing
        feedbackMessage = ""

        Task {
            let result = await eventManager.createEventFromNaturalLanguage(
                inputText,
                referenceDate: selectedDate
            )

            await MainActor.run {
                switch result {
                case .success(let eventTitle):
                    feedbackState = .success
                    feedbackMessage = "Added: \(eventTitle)"
                    inputText = ""

                    // Refresh the events list
                    Task {
                        await eventManager.fetchEvents(for: selectedDate)
                    }
                    onEventCreated?()

                    // Clear success message and close input after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            feedbackState = .idle
                            feedbackMessage = ""
                            isAddingEvent = false
                        }
                    }

                case .failure(let error):
                    feedbackState = .error
                    feedbackMessage = error.localizedDescription

                    // Clear error message after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if feedbackState == .error {
                            feedbackState = .idle
                            feedbackMessage = ""
                        }
                    }
                }
            }
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
