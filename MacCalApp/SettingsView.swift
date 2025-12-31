import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var formatManager = DateFormatManager.shared
    @State private var hotkeyManager = HotkeyManager.shared
    @State private var startAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Date Format")
                    .font(.headline)

                Picker("Format", selection: $formatManager.selectedPreset) {
                    ForEach(DateFormatPreset.allCases) { preset in
                        Text(preset.displayName)
                            .tag(preset)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)

                if formatManager.selectedPreset == .custom {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Custom Format String")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("e.g., EEEE, MMMM d, yyyy", text: $formatManager.customFormatString)
                            .textFieldStyle(.roundedBorder)

                        Text("Preview: \(formatManager.previewFormat(formatManager.customFormatString))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }

                Text("Preview: \(formatManager.formattedDate())")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Startup")
                    .font(.headline)

                Toggle("Launch at login", isOn: $startAtLogin)
                    .onChange(of: startAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Keyboard Shortcut")
                    .font(.headline)

                Text("Toggle calendar popover")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                KeyboardShortcutRecorder(shortcut: Binding(
                    get: { hotkeyManager.currentShortcut },
                    set: { hotkeyManager.currentShortcut = $0 }
                ))
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Format Reference")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 2) {
                    FormatHelpRow(symbol: "yyyy", meaning: "Year (2025)")
                    FormatHelpRow(symbol: "MM", meaning: "Month (01-12)")
                    FormatHelpRow(symbol: "MMM", meaning: "Month (Jan)")
                    FormatHelpRow(symbol: "MMMM", meaning: "Month (January)")
                    FormatHelpRow(symbol: "dd", meaning: "Day (01-31)")
                    FormatHelpRow(symbol: "d", meaning: "Day (1-31)")
                    FormatHelpRow(symbol: "E", meaning: "Day name (Mon)")
                    FormatHelpRow(symbol: "EEEE", meaning: "Day name (Monday)")
                    FormatHelpRow(symbol: "HH", meaning: "Hour 24h (00-23)")
                    FormatHelpRow(symbol: "h", meaning: "Hour 12h (1-12)")
                    FormatHelpRow(symbol: "mm", meaning: "Minutes (00-59)")
                    FormatHelpRow(symbol: "a", meaning: "AM/PM")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 320, height: 580)
        .onAppear {
            checkLaunchAtLoginStatus()
        }
    }

    private func checkLaunchAtLoginStatus() {
        startAtLogin = SMAppService.mainApp.status == .enabled
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            startAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

struct FormatHelpRow: View {
    let symbol: String
    let meaning: String

    var body: some View {
        HStack {
            Text(symbol)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .leading)
            Text(meaning)
        }
    }
}

#Preview {
    SettingsView()
}
