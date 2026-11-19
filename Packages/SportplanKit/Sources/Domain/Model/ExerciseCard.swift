import Foundation

public struct ExerciseCard: Hashable, Sendable {
    public let exercise: LibraryExercise
    public let records: [PersonalRecord]
    public let sessions: [ExerciseSession]
    public let recordSetIds: Set<UUID>
    public let series: [ProgressSeries]

    public init(history: ExerciseHistory) {
        let profile = history.exercise.recordProfile
        self.exercise = history.exercise
        self.records = PersonalRecords.make(history: history)
        self.sessions = history.sessions.sorted { lhs, rhs in
            return lhs.date > rhs.date
        }
        self.recordSetIds = RecordBaseline.empty.recordSetIds(
            in: history.sessions.flatMap(\.sets),
            profile: profile
        )
        self.series = ProgressMetric.metrics(for: profile).map { metric in
            return ProgressSeries(history: history, metric: metric)
        }
    }

    public var profile: RecordProfile {
        return exercise.recordProfile
    }

    public var hasData: Bool {
        return !sessions.isEmpty
    }

    public func hasRecord(in session: ExerciseSession) -> Bool {
        return session.sets.contains { entry in
            return recordSetIds.contains(entry.id)
        }
    }
}
