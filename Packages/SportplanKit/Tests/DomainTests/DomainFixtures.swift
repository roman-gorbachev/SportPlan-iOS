import Domain
import Foundation

enum DomainFixtures {
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    static func makeEquipment(name: String = "Олимпийский гриф", kind: EquipmentKind = .barbell, isArchived: Bool = false) -> Equipment {
        return Equipment(
            id: UUID(),
            name: name,
            kind: kind,
            baseWeight: kind.hasBaseWeight ? Weight(kilograms: 20) : .zero,
            weightStep: Weight(kilograms: 2.5),
            isArchived: isArchived,
            createdAt: referenceDate
        )
    }

    static func makeExercise(name: String, load: ExerciseLoad, metric: ExerciseMetric = .weightReps) -> Exercise {
        return Exercise(
            id: UUID(),
            name: name,
            description: nil,
            load: load,
            metric: metric,
            restSeconds: Exercise.defaultRestSeconds,
            isArchived: false,
            createdAt: referenceDate
        )
    }
}
