import SwiftUI

@main
struct MacCalAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("Settings", id: "settings") {
            SettingsView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize status bar
        statusBarController = StatusBarController.shared

        // Initialize hotkey manager and set up callback
        hotkeyManager = HotkeyManager.shared
        hotkeyManager?.onHotkeyPressed = { [weak self] in
            self?.statusBarController?.togglePopover()
        }

        // Start monitoring for hotkeys
        hotkeyManager?.startMonitoring()

        // Close any windows that opened on launch (Settings window)
        DispatchQueue.main.async {
            for window in NSApp.windows {
                if window.title == "Settings" || window.identifier?.rawValue == "settings" {
                    window.close()
                }
            }
            // Ensure the app doesn't show in dock
            NSApp.setActivationPolicy(.accessory)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager?.stopMonitoring()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
