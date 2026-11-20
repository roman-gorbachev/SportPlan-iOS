public struct ExerciseEditorSnapshot: Hashable, Sendable {
    public let exercise: Exercise
    public let loadKind: ExerciseLoadKind
    public let hasCompletedSets: Bool
    public let programDayCount: Int

    public init(exercise: Exercise, loadKind: ExerciseLoadKind, hasCompletedSets: Bool, programDayCount: Int) {
        self.exercise = exercise
        self.loadKind = loadKind
        self.hasCompletedSets = hasCompletedSets
        self.programDayCount = programDayCount
    }

    public var isMetricLocked: Bool {
        return hasCompletedSets
    }

    public var draft: ExerciseDraft {
        return ExerciseDraft(exercise: exercise, loadKind: loadKind)
    }
}
