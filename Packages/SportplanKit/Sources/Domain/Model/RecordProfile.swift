public enum RecordProfile: Hashable, Sendable {
    case weighted
    case bodyweightReps
    case duration

    public init(loadKind: ExerciseLoadKind, metric: ExerciseMetric) {
        if metric == .duration {
            self = .duration
            return
        }
        switch loadKind {
        case .equipment:
            self = .weighted
        case .bodyweight:
            self = .bodyweightReps
        }
    }
}
