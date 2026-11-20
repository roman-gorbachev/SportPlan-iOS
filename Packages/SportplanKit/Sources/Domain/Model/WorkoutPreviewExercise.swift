public struct WorkoutPreviewExercise: Identifiable, Hashable, Sendable {
    public let item: PlannedExerciseItem
    public let plannedSets: [SetEntry]
    public let hasHistory: Bool
    public let progressionWeight: Weight?

    public init(item: PlannedExerciseItem, plannedSets: [SetEntry], hasHistory: Bool, progressionWeight: Weight?) {
        self.item = item
        self.plannedSets = plannedSets
        self.hasHistory = hasHistory
        self.progressionWeight = progressionWeight
    }

    public var id: PlannedExerciseItem.ID {
        return item.id
    }
}
