public struct PlannedExerciseTargets: Hashable, Sendable {
    private static let defaultSets = 3
    private static let defaultMinimumReps = 8
    private static let defaultMaximumReps = 12
    private static let minimumSets = 1
    private static let maximumSets = 10
    private static let minimumReps = 1
    private static let maximumReps = 100
    private static let setStep = 1
    private static let repStep = 1

    public var sets: Int
    public var reps: RepRange?
    public var restSeconds: Int

    public init(sets: Int, reps: RepRange?, restSeconds: Int) {
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
    }

    public init(defaultsFor exercise: Exercise) {
        self.init(defaultsFor: exercise.metric, restSeconds: exercise.restSeconds)
    }

    public init(defaultsFor metric: ExerciseMetric, restSeconds: Int) {
        let reps: RepRange?
        switch metric {
        case .weightReps:
            reps = RepRange(min: Self.defaultMinimumReps, max: Self.defaultMaximumReps)
        case .duration:
            reps = nil
        }
        self.init(sets: Self.defaultSets, reps: reps, restSeconds: restSeconds)
    }

    public var canIncrementSets: Bool {
        return sets + Self.setStep <= Self.maximumSets
    }

    public var canDecrementSets: Bool {
        return sets - Self.setStep >= Self.minimumSets
    }

    public mutating func incrementSets() {
        sets = Swift.min(sets + Self.setStep, Self.maximumSets)
    }

    public mutating func decrementSets() {
        sets = Swift.max(sets - Self.setStep, Self.minimumSets)
    }

    public var canIncrementMinimumReps: Bool {
        guard let reps else {
            return false
        }
        return reps.min + Self.repStep <= Self.maximumReps
    }

    public var canDecrementMinimumReps: Bool {
        guard let reps else {
            return false
        }
        return reps.min - Self.repStep >= Self.minimumReps
    }

    public var canIncrementMaximumReps: Bool {
        guard let reps else {
            return false
        }
        return reps.max + Self.repStep <= Self.maximumReps
    }

    public var canDecrementMaximumReps: Bool {
        guard let reps else {
            return false
        }
        return reps.max - Self.repStep >= Self.minimumReps
    }

    public mutating func incrementMinimumReps() {
        guard let reps else {
            return
        }
        let minimum = Swift.min(reps.min + Self.repStep, Self.maximumReps)
        self.reps = RepRange(min: minimum, max: Swift.max(reps.max, minimum))
    }

    public mutating func decrementMinimumReps() {
        guard let reps else {
            return
        }
        self.reps = RepRange(min: Swift.max(reps.min - Self.repStep, Self.minimumReps), max: reps.max)
    }

    public mutating func incrementMaximumReps() {
        guard let reps else {
            return
        }
        self.reps = RepRange(min: reps.min, max: Swift.min(reps.max + Self.repStep, Self.maximumReps))
    }

    public mutating func decrementMaximumReps() {
        guard let reps else {
            return
        }
        let maximum = Swift.max(reps.max - Self.repStep, Self.minimumReps)
        self.reps = RepRange(min: Swift.min(reps.min, maximum), max: maximum)
    }

    public var canIncrementRest: Bool {
        return restSeconds + Exercise.restStepSeconds <= Exercise.maximumRestSeconds
    }

    public var canDecrementRest: Bool {
        return restSeconds - Exercise.restStepSeconds >= Exercise.minimumRestSeconds
    }

    public mutating func incrementRest() {
        restSeconds = Swift.min(restSeconds + Exercise.restStepSeconds, Exercise.maximumRestSeconds)
    }

    public mutating func decrementRest() {
        restSeconds = Swift.max(restSeconds - Exercise.restStepSeconds, Exercise.minimumRestSeconds)
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
