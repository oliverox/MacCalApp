import Foundation
import AppKit

@Observable
class HotkeyManager {
    static let shared = HotkeyManager()

    private let defaults = UserDefaults.standard
    private let shortcutKey = "globalKeyboardShortcut"

    var currentShortcut: KeyboardShortcut {
        didSet {
            saveShortcut()
        }
    }

    var onHotkeyPressed: (() -> Void)?

    private var globalMonitor: Any?
    private var localMonitor: Any?

    private init() {
        currentShortcut = HotkeyManager.loadShortcut() ?? .defaultShortcut
    }

    func startMonitoring() {
        stopMonitoring()

        // Global monitor (when app not focused)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }

        // Local monitor (when app is focused)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil // Consume the event
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let relevantModifiers: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
        let eventModifiers = event.modifierFlags.intersection(relevantModifiers)
        let shortcutModifiers = currentShortcut.modifiers.intersection(relevantModifiers)

        if event.keyCode == currentShortcut.keyCode && eventModifiers == shortcutModifiers {
            DispatchQueue.main.async { [weak self] in
                self?.onHotkeyPressed?()
            }
            return true
        }
        return false
    }

    private func saveShortcut() {
        if let data = try? JSONEncoder().encode(currentShortcut) {
            defaults.set(data, forKey: shortcutKey)
        }
    }

    private static func loadShortcut() -> KeyboardShortcut? {
        guard let data = UserDefaults.standard.data(forKey: "globalKeyboardShortcut"),
              let shortcut = try? JSONDecoder().decode(KeyboardShortcut.self, from: data)
        else { return nil }
        return shortcut
    }
}
