import Foundation

public enum PersonalRecords {
    private struct Rank: Comparable {
        let primary: Int
        let secondary: Int

        static func < (lhs: Rank, rhs: Rank) -> Bool {
            if lhs.primary != rhs.primary {
                return lhs.primary < rhs.primary
            }
            return lhs.secondary < rhs.secondary
        }
    }

    private static let minimumReps = 1
    private static let minimumDurationSeconds = 1

    public static func make(history: ExerciseHistory) -> [PersonalRecord] {
        let profile = history.exercise.recordProfile
        let dated = history.chronologicalSessions.flatMap { session in
            return RecordBaseline.chronological(session.sets).map { entry in
                return (entry: entry, date: session.date)
            }
        }
        return PersonalRecordKind.kinds(for: profile).compactMap { kind in
            var best: (record: PersonalRecord, rank: Rank)?
            for item in dated {
                guard let measure = measure(item.entry, kind: kind) else {
                    continue
                }
                if let current = best, measure.rank <= current.rank {
                    continue
                }
                let record = PersonalRecord(kind: kind, entry: item.entry, value: measure.value, date: item.date)
                best = (record, measure.rank)
            }
            return best?.record
        }
    }

    private static func measure(_ entry: SetEntry, kind: PersonalRecordKind) -> (value: Int, rank: Rank)? {
        switch kind {
        case .maxWeight:
            guard let reps = entry.reps, reps >= minimumReps else {
                return nil
            }
            return (entry.weight.grams, Rank(primary: entry.weight.grams, secondary: reps))
        case .estimatedOneRepMax:
            guard let estimate = EstimatedOneRepMax.make(weight: entry.weight, reps: entry.reps) else {
                return nil
            }
            return (estimate.grams, Rank(primary: estimate.grams, secondary: entry.weight.grams))
        case .maxReps:
            guard let reps = entry.reps, reps >= minimumReps else {
                return nil
            }
            return (reps, Rank(primary: reps, secondary: entry.weight.grams))
        case .maxWeightedReps:
            guard let reps = entry.reps, reps >= minimumReps, entry.weight > .zero else {
                return nil
            }
            return (entry.weight.grams, Rank(primary: entry.weight.grams, secondary: reps))
        case .maxDuration:
            guard let duration = entry.durationSeconds, duration >= minimumDurationSeconds else {
                return nil
            }
            return (duration, Rank(primary: duration, secondary: entry.weight.grams))
        }
    }
}
