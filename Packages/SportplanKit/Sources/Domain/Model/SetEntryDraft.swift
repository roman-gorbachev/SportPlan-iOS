public struct SetEntryDraft: Hashable, Sendable {
    private static let minimumReps = 0
    private static let repStep = 1
    private static let minimumDurationSeconds = 0

    public var weight: Weight
    public var reps: Int?
    public var durationSeconds: Int?

    public init(weight: Weight, reps: Int?, durationSeconds: Int?) {
        self.weight = weight
        self.reps = reps
        self.durationSeconds = durationSeconds
    }

    public init(_ entry: SetEntry) {
        self.init(weight: entry.weight, reps: entry.reps, durationSeconds: entry.durationSeconds)
    }

    public func canDecrementWeight(for exercise: LibraryExercise) -> Bool {
        return weight > exercise.minimumWeight
    }

    public mutating func incrementWeight(for exercise: LibraryExercise) {
        weight = Swift.max(weight + exercise.weightStep, exercise.minimumWeight)
    }

    public mutating func decrementWeight(for exercise: LibraryExercise) {
        weight = Swift.max(weight - exercise.weightStep, exercise.minimumWeight)
    }

    public var canDecrementReps: Bool {
        return (reps ?? Self.minimumReps) > Self.minimumReps
    }

    public mutating func incrementReps() {
        reps = (reps ?? Self.minimumReps) + Self.repStep
    }

    public mutating func decrementReps() {
        reps = Swift.max((reps ?? Self.minimumReps) - Self.repStep, Self.minimumReps)
    }

    public func isValid(for metric: ExerciseMetric) -> Bool {
        guard weight >= .zero else {
            return false
        }
        switch metric {
        case .weightReps:
            guard let reps, durationSeconds == nil else {
                return false
            }
            return reps >= Self.minimumReps
        case .duration:
            guard reps == nil else {
                return false
            }
            return (durationSeconds ?? Self.minimumDurationSeconds) >= Self.minimumDurationSeconds
        }
    }

    public func applied(to entry: SetEntry) -> SetEntry {
        var updated = entry
        updated.weight = weight
        updated.reps = reps
        updated.durationSeconds = durationSeconds
        return updated
    }
}
