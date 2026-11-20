public struct LibraryExercise: Identifiable, Hashable, Sendable {
    public let exercise: Exercise
    public let equipment: Equipment?

    public init(exercise: Exercise, equipment: Equipment?) {
        self.exercise = exercise
        self.equipment = equipment
    }

    public var id: Exercise.ID {
        return exercise.id
    }

    public var loadKind: ExerciseLoadKind {
        guard let equipment else {
            return .bodyweight
        }
        return .equipment(equipment.kind)
    }

    public var metric: ExerciseMetric {
        return exercise.metric
    }

    public var recordProfile: RecordProfile {
        return RecordProfile(loadKind: loadKind, metric: metric)
    }

    public var weightScale: WeightScale {
        return WeightScale(equipment: equipment)
    }

    public var weightStep: Weight {
        return weightScale.step
    }

    public var minimumWeight: Weight {
        return weightScale.minimum
    }

    public var usesPlates: Bool {
        return equipment?.kind.usesPlates ?? false
    }
}
