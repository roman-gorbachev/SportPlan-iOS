import Foundation

public struct ExerciseDraft: Hashable, Sendable {
    private static let minimumRestSeconds = 0
    private static let maximumRestSeconds = 600
    private static let restStepSeconds = 15

    public var name: String
    public var loadKind: ExerciseLoadKind {
        didSet {
            guard loadKind != oldValue else {
                return
            }
            equipmentId = nil
            if !loadKind.allowsDuration {
                metric = .weightReps
            }
        }
    }
    public var equipmentId: UUID?
    public var metric: ExerciseMetric
    public var restSeconds: Int
    public var description: String

    public init(
        name: String = "",
        loadKind: ExerciseLoadKind,
        equipmentId: UUID? = nil,
        metric: ExerciseMetric = .weightReps,
        restSeconds: Int = Exercise.defaultRestSeconds,
        description: String = ""
    ) {
        self.name = name
        self.loadKind = loadKind
        self.equipmentId = equipmentId
        self.metric = metric
        self.restSeconds = restSeconds
        self.description = description
    }

    public init(quickExercise: QuickExercise, name: String) {
        self.init(name: name, loadKind: quickExercise.loadKind, metric: quickExercise.metric)
    }

    public var trimmedName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var trimmedDescription: String? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    public var load: ExerciseLoad? {
        guard loadKind.equipmentKind != nil else {
            return .bodyweight
        }
        return equipmentId.map { id in
            return ExerciseLoad.equipment(id: id)
        }
    }

    public var canIncrementRest: Bool {
        return restSeconds + Self.restStepSeconds <= Self.maximumRestSeconds
    }

    public var canDecrementRest: Bool {
        return restSeconds - Self.restStepSeconds >= Self.minimumRestSeconds
    }

    public mutating func incrementRest() {
        restSeconds = min(restSeconds + Self.restStepSeconds, Self.maximumRestSeconds)
    }

    public mutating func decrementRest() {
        restSeconds = max(restSeconds - Self.restStepSeconds, Self.minimumRestSeconds)
    }

    public var validationIssues: Set<ExerciseValidationIssue> {
        var issues = Set<ExerciseValidationIssue>()
        if trimmedName.isEmpty {
            issues.insert(.emptyName)
        }
        if load == nil {
            issues.insert(.missingEquipment)
        }
        if metric == .duration, !loadKind.allowsDuration {
            issues.insert(.durationNotAllowed)
        }
        if restSeconds < Self.minimumRestSeconds || restSeconds > Self.maximumRestSeconds {
            issues.insert(.restOutOfRange)
        }
        return issues
    }

    public var isValid: Bool {
        return validationIssues.isEmpty
    }
}
