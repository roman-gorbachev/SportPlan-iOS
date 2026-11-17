import Foundation

enum AppTab: Hashable, CaseIterable {
    case workout
    case programs
    case history

    var title: String {
        switch self {
        case .workout:
            return String(localized: "tab.workout")
        case .programs:
            return String(localized: "tab.programs")
        case .history:
            return String(localized: "tab.history")
        }
    }

    var systemImage: String {
        switch self {
        case .workout:
            return "dumbbell"
        case .programs:
            return "list.bullet.rectangle"
        case .history:
            return "calendar"
        }
    }
}
