public struct LibraryExercise: Identifiable, Hashable, Sendable {
    private static let bodyweightWeightStep = Weight(grams: 2_500)

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

    public var weightStep: Weight {
        return equipment?.weightStep ?? Self.bodyweightWeightStep
    }

    public var minimumWeight: Weight {
        guard let equipment, equipment.kind.hasBaseWeight else {
            return .zero
        }
        return equipment.baseWeight
    }

    public var usesPlates: Bool {
        return equipment?.kind.usesPlates ?? false
    }
}
