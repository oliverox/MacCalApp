import SwiftUI

@main
struct MacCalAppApp: App {
    @State private var formatManager = DateFormatManager.shared
    @State private var currentTime = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            CalendarPopoverView()
        } label: {
            Text(formatManager.formattedDate(currentTime))
                .onReceive(timer) { _ in
                    currentTime = Date()
                }
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
