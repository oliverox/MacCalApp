import Foundation
import SwiftUI

enum DateFormatPreset: String, CaseIterable, Identifiable {
    case shortDate = "MMM d"
    case numericDate = "MM/dd/yyyy"
    case dayDate = "E MMM d"
    case isoDate = "yyyy-MM-dd"
    case timeOnly = "h:mm a"
    case dateTime = "MMM d h:mm a"
    case fullDateTime = "E MMM d h:mm a"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .shortDate: return "Dec 30"
        case .numericDate: return "12/30/2025"
        case .dayDate: return "Mon Dec 30"
        case .isoDate: return "2025-12-30"
        case .timeOnly: return "12:30 PM"
        case .dateTime: return "Dec 30 12:30 PM"
        case .fullDateTime: return "Mon Dec 30 12:30 PM"
        case .custom: return "Custom..."
        }
    }

    var formatString: String {
        rawValue
    }
}

@Observable
class DateFormatManager {
    static let shared = DateFormatManager()

    private let defaults = UserDefaults.standard
    private let presetKey = "selectedPreset"
    private let customFormatKey = "customFormatString"

    var selectedPreset: DateFormatPreset {
        didSet {
            defaults.set(selectedPreset.rawValue, forKey: presetKey)
        }
    }

    var customFormatString: String {
        didSet {
            defaults.set(customFormatString, forKey: customFormatKey)
            cachedFormatter = nil
        }
    }

    private var cachedFormatter: DateFormatter?
    private var cachedFormatString: String?

    var currentFormatString: String {
        if selectedPreset == .custom {
            return customFormatString.isEmpty ? "MMM d h:mm a" : customFormatString
        }
        return selectedPreset.formatString
    }

    private init() {
        if let savedPreset = defaults.string(forKey: presetKey),
           let preset = DateFormatPreset(rawValue: savedPreset) {
            self.selectedPreset = preset
        } else {
            self.selectedPreset = .dateTime
        }

        self.customFormatString = defaults.string(forKey: customFormatKey) ?? "EEEE MMMM d yyyy 'at' h:mm a"
    }

    func formattedDate(_ date: Date = Date()) -> String {
        let formatString = currentFormatString

        if cachedFormatter == nil || cachedFormatString != formatString {
            cachedFormatter = DateFormatter()
            cachedFormatter?.dateFormat = formatString
            cachedFormatString = formatString
        }

        return cachedFormatter?.string(from: date) ?? ""
    }

    func previewFormat(_ formatString: String, date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        return formatter.string(from: date)
    }

    func isValidFormat(_ formatString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        let result = formatter.string(from: Date())
        return !result.isEmpty
    }
}
