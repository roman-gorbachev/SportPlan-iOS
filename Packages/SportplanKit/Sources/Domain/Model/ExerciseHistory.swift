public struct ExerciseHistory: Hashable, Sendable {
    public let exercise: LibraryExercise
    public let sessions: [ExerciseSession]

    public init(exercise: LibraryExercise, sessions: [ExerciseSession]) {
        self.exercise = exercise
        self.sessions = sessions
    }

    var chronologicalSessions: [ExerciseSession] {
        return sessions.sorted { lhs, rhs in
            return lhs.date < rhs.date
        }
    }
}
