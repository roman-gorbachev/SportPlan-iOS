import Foundation

public struct RecordBaseline: Hashable, Sendable {
    private struct RepsAtWeight: Hashable, Sendable {
        let weight: Weight
        let reps: Int

        func covers(_ other: RepsAtWeight) -> Bool {
            return weight >= other.weight && reps >= other.reps
        }
    }

    private static let minimumReps = 1
    private static let minimumDurationSeconds = 1

    public static let empty = RecordBaseline()

    private var bestWeight: Weight?
    private var bestOneRepMax: Weight?
    private var bodyweightFront: [RepsAtWeight] = []
    private var bestDurationSeconds: Int?

    public init() {}

    public init(sets: [SetEntry]) {
        for entry in sets where Self.counts(entry) {
            include(entry)
        }
    }

    public static func counts(_ entry: SetEntry) -> Bool {
        return entry.isCompleted && !entry.isWarmup
    }

    public func isRecord(_ entry: SetEntry, profile: RecordProfile) -> Bool {
        switch profile {
        case .weighted:
            guard Self.hasReps(entry) else {
                return false
            }
            let beatsWeight = bestWeight.map { best in
                return entry.weight > best
            } ?? false
            guard
                let bestOneRepMax,
                let estimate = EstimatedOneRepMax.make(weight: entry.weight, reps: entry.reps)
            else {
                return beatsWeight
            }
            return beatsWeight || estimate > bestOneRepMax
        case .bodyweightReps:
            guard let point = Self.repsAtWeight(entry), !bodyweightFront.isEmpty else {
                return false
            }
            return !bodyweightFront.contains { existing in
                return existing.covers(point)
            }
        case .duration:
            guard let duration = Self.duration(entry), let best = bestDurationSeconds else {
                return false
            }
            return duration > best
        }
    }

    public mutating func include(_ entry: SetEntry) {
        if Self.hasReps(entry) {
            bestWeight = max(bestWeight ?? entry.weight, entry.weight)
        }
        if let estimate = EstimatedOneRepMax.make(weight: entry.weight, reps: entry.reps) {
            bestOneRepMax = max(bestOneRepMax ?? estimate, estimate)
        }
        if let point = Self.repsAtWeight(entry), !bodyweightFront.contains(where: { existing in return existing.covers(point) }) {
            bodyweightFront.removeAll { existing in
                return point.covers(existing)
            }
            bodyweightFront.append(point)
        }
        if let duration = Self.duration(entry) {
            bestDurationSeconds = max(bestDurationSeconds ?? duration, duration)
        }
    }

    public func recordSetIds(in sets: [SetEntry], profile: RecordProfile) -> Set<UUID> {
        var baseline = self
        var recordIds = Set<UUID>()
        for entry in Self.chronological(sets) {
            if baseline.isRecord(entry, profile: profile) {
                recordIds.insert(entry.id)
            }
            baseline.include(entry)
        }
        return recordIds
    }

    static func chronological(_ sets: [SetEntry]) -> [SetEntry] {
        return sets.filter(counts).sorted { lhs, rhs in
            let lhsDate = lhs.completedAt ?? .distantPast
            let rhsDate = rhs.completedAt ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }
            return lhs.position < rhs.position
        }
    }

    private static func hasReps(_ entry: SetEntry) -> Bool {
        guard let reps = entry.reps else {
            return false
        }
        return reps >= minimumReps
    }

    private static func repsAtWeight(_ entry: SetEntry) -> RepsAtWeight? {
        guard let reps = entry.reps, reps >= minimumReps else {
            return nil
        }
        return RepsAtWeight(weight: entry.weight, reps: reps)
    }

    private static func duration(_ entry: SetEntry) -> Int? {
        guard let duration = entry.durationSeconds, duration >= minimumDurationSeconds else {
            return nil
        }
        return duration
    }
}

