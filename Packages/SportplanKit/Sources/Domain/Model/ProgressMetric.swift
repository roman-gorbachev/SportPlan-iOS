public enum ProgressMetric: Hashable, Sendable {
    case estimatedOneRepMax
    case maxWeight
    case maxReps
    case maxDuration

    private static let minimumReps = 1
    private static let minimumDurationSeconds = 1

    public static func metrics(for profile: RecordProfile) -> [ProgressMetric] {
        switch profile {
        case .weighted:
            return [.estimatedOneRepMax, .maxWeight]
        case .bodyweightReps:
            return [.maxReps]
        case .duration:
            return [.maxDuration]
        }
    }

    public func value(of entry: SetEntry) -> Int? {
        switch self {
        case .estimatedOneRepMax:
            return EstimatedOneRepMax.make(weight: entry.weight, reps: entry.reps)?.grams
        case .maxWeight:
            guard let reps = entry.reps, reps >= Self.minimumReps else {
                return nil
            }
            return entry.weight.grams
        case .maxReps:
            guard let reps = entry.reps, reps >= Self.minimumReps else {
                return nil
            }
            return reps
        case .maxDuration:
            guard let duration = entry.durationSeconds, duration >= Self.minimumDurationSeconds else {
                return nil
            }
            return duration
        }
    }
}
