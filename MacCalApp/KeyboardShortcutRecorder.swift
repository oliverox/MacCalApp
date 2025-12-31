import SwiftUI
import AppKit

struct KeyboardShortcutRecorder: View {
    @Binding var shortcut: KeyboardShortcut
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack(spacing: 12) {
            // Shortcut display
            Text(isRecording ? "Press shortcut..." : shortcut.displayString)
                .font(.system(.body, design: .monospaced))
                .frame(minWidth: 100)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isRecording ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
                )

            if !isRecording {
                Button("Record") {
                    startRecording()
                }
                .buttonStyle(.bordered)

                Button("Reset") {
                    shortcut = .defaultShortcut
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.caption)
            } else {
                Button("Cancel") {
                    stopRecording()
                }
                .buttonStyle(.bordered)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true

        // Stop the global hotkey monitoring while recording
        HotkeyManager.shared.stopMonitoring()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let relevantModifiers: NSEvent.ModifierFlags = [.command, .shift, .option, .control]
            let modifiers = event.modifierFlags.intersection(relevantModifiers)

            // Require at least one modifier key
            guard !modifiers.isEmpty else {
                return event
            }

            // Escape cancels recording
            if event.keyCode == 53 { // Escape key code
                stopRecording()
                return nil
            }

            // Don't allow modifier-only shortcuts (must have a non-modifier key)
            let modifierOnlyKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63] // Modifier key codes
            if modifierOnlyKeyCodes.contains(event.keyCode) {
                return event
            }

            shortcut = KeyboardShortcut(keyCode: event.keyCode, modifiers: modifiers)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }

        // Resume global hotkey monitoring
        HotkeyManager.shared.startMonitoring()
    }
}

#Preview {
    KeyboardShortcutRecorder(shortcut: .constant(.defaultShortcut))
        .padding()
}
