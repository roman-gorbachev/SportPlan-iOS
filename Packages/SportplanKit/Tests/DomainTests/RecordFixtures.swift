import Domain
import Foundation

enum RecordFixtures {
    static let secondsPerDay: TimeInterval = 86_400

    static func day(_ index: Int) -> Date {
        return DomainFixtures.referenceDate.addingTimeInterval(TimeInterval(index) * secondsPerDay)
    }

    static func set(
        kilograms: Double,
        reps: Int? = nil,
        durationSeconds: Int? = nil,
        isWarmup: Bool = false,
        at date: Date,
        position: Int = 0
    ) -> SetEntry {
        return DomainFixtures.makeSet(
            position: position,
            kilograms: kilograms,
            reps: reps,
            durationSeconds: durationSeconds,
            isWarmup: isWarmup,
            completedAt: date
        )
    }

    static func session(day index: Int, _ sets: [SetEntry]) -> ExerciseSession {
        return ExerciseSession(workoutId: UUID(), date: day(index), sets: sets)
    }
}
