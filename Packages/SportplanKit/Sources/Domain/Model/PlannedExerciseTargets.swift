public struct PlannedExerciseTargets: Hashable, Sendable {
    private static let defaultSets = 3
    private static let defaultMinimumReps = 8
    private static let defaultMaximumReps = 12
    private static let minimumSets = 1
    private static let maximumSets = 10
    private static let maximumReps = 100

    public var sets: Int
    public var reps: RepRange?
    public var restSeconds: Int

    public init(sets: Int, reps: RepRange?, restSeconds: Int) {
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
    }

    public init(defaultsFor exercise: Exercise) {
        let reps: RepRange?
        switch exercise.metric {
        case .weightReps:
            reps = RepRange(min: Self.defaultMinimumReps, max: Self.defaultMaximumReps)
        case .duration:
            reps = nil
        }
        self.init(sets: Self.defaultSets, reps: reps, restSeconds: exercise.restSeconds)
    }

    public func validationIssues(for metric: ExerciseMetric) -> Set<PlannedExerciseValidationIssue> {
        var issues = Set<PlannedExerciseValidationIssue>()
        if sets < Self.minimumSets || sets > Self.maximumSets {
            issues.insert(.setsOutOfRange)
        }
        switch metric {
        case .weightReps:
            if let reps {
                if reps.max > Self.maximumReps {
                    issues.insert(.repsOutOfRange)
                }
            } else {
                issues.insert(.missingReps)
            }
        case .duration:
            if reps != nil {
                issues.insert(.repsNotAllowed)
            }
        }
        if restSeconds < Exercise.minimumRestSeconds || restSeconds > Exercise.maximumRestSeconds {
            issues.insert(.restOutOfRange)
        }
        return issues
    }
}
