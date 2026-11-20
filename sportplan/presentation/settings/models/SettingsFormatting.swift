import Domain
import Foundation

enum SettingsFormatting {
    static func importMessage(_ summary: BackupSummary) -> String {
        let workouts = String(localized: "settings.data.confirm.workouts \(summary.workoutCount)")
        let exercises = String(localized: "settings.data.confirm.exercises \(summary.exerciseCount)")
        let programs = String(localized: "settings.data.confirm.programs \(summary.programCount)")
        return String(localized: "settings.data.confirm.message \(exportDate(summary.exportedAt)) \(workouts) \(exercises) \(programs)")
    }

    static func importError(_ error: any Error) -> String {
        guard let error = error as? BackupError else {
            return String(localized: "settings.data.error.unknown")
        }
        switch error {
        case .unreadable:
            return String(localized: "settings.data.error.unreadable")
        case .newerVersion:
            return String(localized: "settings.data.error.newerVersion")
        case .invalidData:
            return String(localized: "settings.data.error.invalidData")
        case .workoutInProgress:
            return String(localized: "settings.data.error.workoutInProgress")
        }
    }

    private static func exportDate(_ date: Date) -> String {
        let style = Date.VerbatimFormatStyle(
            format: "\(day: .defaultDigits) \(month: .wide) \(year: .defaultDigits)",
            locale: AppLocale.current,
            timeZone: .current,
            calendar: .current
        )
        return date.formatted(style)
    }
}
