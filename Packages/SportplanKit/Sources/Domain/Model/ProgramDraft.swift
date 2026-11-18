import Foundation

public struct ProgramDraft: Hashable, Sendable {
    public var name: String

    public init(name: String = "") {
        self.name = name
    }

    public var trimmedName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var validationIssues: Set<ProgramValidationIssue> {
        var issues = Set<ProgramValidationIssue>()
        if trimmedName.isEmpty {
            issues.insert(.emptyName)
        }
        return issues
    }

    public var isValid: Bool {
        return validationIssues.isEmpty
    }
}
