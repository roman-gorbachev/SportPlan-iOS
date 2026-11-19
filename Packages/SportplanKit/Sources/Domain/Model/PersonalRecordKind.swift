public enum PersonalRecordKind: Hashable, Sendable {
    case maxWeight
    case estimatedOneRepMax
    case maxReps
    case maxWeightedReps
    case maxDuration

    public static func kinds(for profile: RecordProfile) -> [PersonalRecordKind] {
        switch profile {
        case .weighted:
            return [.maxWeight, .estimatedOneRepMax]
        case .bodyweightReps:
            return [.maxReps, .maxWeightedReps]
        case .duration:
            return [.maxDuration]
        }
    }
}
