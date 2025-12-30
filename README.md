# MacCalApp

A native macOS menu bar calendar app built with SwiftUI.

## Features

- **Menu Bar Integration** - Displays current date/time in the menu bar with customizable format
- **Calendar View** - Click to open a calendar popup showing the current month
- **Month Navigation** - Smooth sliding animations when navigating between months
- **Date Selection** - Click any date to view events for that day
- **Calendar Events** - Integrates with macOS Calendar via EventKit to display your events (supports Apple Calendar, Google Calendar, and other calendars synced to macOS)
- **Customizable Format** - Choose from preset formats or create your own custom date/time format
- **Launch at Login** - Option to start the app automatically when you log in
- **No Dock Icon** - Runs cleanly as a menu bar-only app

## Screenshots

The app appears in your menu bar showing the current date/time. Click to reveal the calendar:

- Month and year header with navigation arrows
- Weekday headers (S M T W T F S)
- Day grid with today highlighted
- Events list for the selected date
- Quick access to Today and Settings

## Requirements

- macOS 14.0 or later
- Xcode 15+ (for building)

## Building

1. Open `MacCalApp.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run (⌘R)

## Usage

### Date Format

Access Settings via the gear icon in the calendar popup. Available preset formats:

- `Dec 30` (MMM d)
- `12/30/2025` (MM/dd/yyyy)
- `Mon Dec 30` (E MMM d)
- `2025-12-30` (yyyy-MM-dd)
- `12:30 PM` (h:mm a)
- `Dec 30 12:30 PM` (MMM d h:mm a)
- `Mon Dec 30 12:30 PM` (E MMM d h:mm a)
- Custom format string

### Calendar Access

On first launch, the app will request access to your calendars. Grant access to see your events from all calendars synced to macOS (Apple Calendar, Google Calendar, etc.).

## Project Structure

```
MacCalApp/
├── MacCalAppApp.swift          # App entry point, menu bar setup
├── CalendarPopoverView.swift   # Main calendar popup UI
├── CalendarGridView.swift      # Month grid with day cells
├── EventsListView.swift        # Events display for selected date
├── CalendarEventManager.swift  # EventKit integration
├── DateFormatManager.swift     # Format handling & persistence
├── SettingsView.swift          # Preferences window
├── Assets.xcassets/            # App icons
└── Info.plist                  # App configuration
```

## License

MIT
