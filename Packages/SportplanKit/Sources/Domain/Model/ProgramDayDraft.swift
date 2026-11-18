import Foundation

public struct ProgramDayDraft: Hashable, Sendable {
    private static let maximumLabelLength = 3

    public var name: String
    public var label: String

    public init(name: String = "", label: String = "") {
        self.name = name
        self.label = label
    }

    public init(day: ProgramDay) {
        self.init(name: day.name, label: day.label ?? "")
    }

    public var trimmedName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var trimmedLabel: String? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public var validationIssues: Set<ProgramValidationIssue> {
        var issues = Set<ProgramValidationIssue>()
        if trimmedName.isEmpty {
            issues.insert(.emptyName)
        }
        if let trimmedLabel, trimmedLabel.count > Self.maximumLabelLength {
            issues.insert(.labelTooLong)
        }
        return issues
    }

    public var isValid: Bool {
        return validationIssues.isEmpty
    }
}
