import Domain
import Foundation
import Testing

struct WorkoutSetPlannerTests {
    private static let bench = DomainFixtures.makeLibraryExercise()
    private static let plank = DomainFixtures.makeLibraryExercise(name: "Планка", kind: nil, metric: .duration)

    private static func values(_ sets: [SetEntry]) -> [String] {
        return sets.map { entry in
            return "\(entry.weight.kilograms)×\(entry.reps.map(String.init) ?? "-")/\(entry.durationSeconds.map(String.init) ?? "-")"
        }
    }

    @Test func plannedRowsFollowPreviousWorkingSetsByNumber() {
        let previous = [
            DomainFixtures.makeSet(position: 0, kilograms: 40, reps: 10, isWarmup: true),
            DomainFixtures.makeSet(position: 1, kilograms: 60, reps: 8),
            DomainFixtures.makeSet(position: 2, kilograms: 62.5, reps: 8),
            DomainFixtures.makeSet(position: 3, kilograms: 62.5, reps: 7),
            DomainFixtures.makeSet(position: 4, kilograms: 65, reps: 5),
        ]
        let workoutExerciseId = UUID()
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: workoutExerciseId,
            targetSets: 3,
            targetReps: RepRange(min: 8, max: 12),
            previousSets: previous
        )
        #expect(Self.values(sets) == ["60.0×8/-", "62.5×8/-", "62.5×7/-"])
        #expect(sets.map(\.position) == [0, 1, 2])
        #expect(sets.allSatisfy { entry in return entry.state == .planned && !entry.isWarmup && entry.workoutExerciseId == workoutExerciseId })
    }

    @Test func shorterHistoryRepeatsTheLastSet() {
        let previous = [
            DomainFixtures.makeSet(position: 0, kilograms: 60, reps: 8),
            DomainFixtures.makeSet(position: 1, kilograms: 62.5, reps: 6),
        ]
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: 4,
            targetReps: RepRange(min: 8, max: 12),
            previousSets: previous
        )
        #expect(Self.values(sets) == ["60.0×8/-", "62.5×6/-", "62.5×6/-", "62.5×6/-"])
    }

    @Test func withoutHistoryRowsStartFromBaseWeightAndLowerRepTarget() {
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: 3,
            targetReps: RepRange(min: 6, max: 10),
            previousSets: []
        )
        #expect(Self.values(sets) == ["20.0×6/-", "20.0×6/-", "20.0×6/-"])
        let dumbbells = DomainFixtures.makeLibraryExercise(name: "Жим гантелей", kind: .dumbbell)
        let dumbbellSets = WorkoutSetPlanner.plannedSets(
            for: dumbbells,
            workoutExerciseId: UUID(),
            targetSets: 1,
            targetReps: RepRange(min: 10, max: 12),
            previousSets: []
        )
        #expect(Self.values(dumbbellSets) == ["0.0×10/-"])
    }

    @Test func timedRowsWithoutHistoryHaveNoDuration() {
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.plank,
            workoutExerciseId: UUID(),
            targetSets: 2,
            targetReps: nil,
            previousSets: []
        )
        #expect(Self.values(sets) == ["0.0×-/-", "0.0×-/-"])
        let previous = [DomainFixtures.makeSet(position: 0, kilograms: 0, reps: nil, durationSeconds: 75)]
        let repeated = WorkoutSetPlanner.plannedSets(
            for: Self.plank,
            workoutExerciseId: UUID(),
            targetSets: 2,
            targetReps: nil,
            previousSets: previous
        )
        #expect(Self.values(repeated) == ["0.0×-/75", "0.0×-/75"])
    }

    @Test func unplannedExerciseRepeatsPreviousStructureOrStartsWithOneRow() {
        let previous = [
            DomainFixtures.makeSet(position: 0, kilograms: 40, reps: 10, isWarmup: true),
            DomainFixtures.makeSet(position: 1, kilograms: 60, reps: 8),
            DomainFixtures.makeSet(position: 2, kilograms: 60, reps: 7),
        ]
        let repeated = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: nil,
            targetReps: nil,
            previousSets: previous
        )
        #expect(Self.values(repeated) == ["60.0×8/-", "60.0×7/-"])
        let fresh = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: nil,
            targetReps: nil,
            previousSets: []
        )
        #expect(Self.values(fresh) == ["20.0×8/-"])
    }

    @Test func newWorkingSetCopiesTheLastWorkingRow() {
        let workoutExerciseId = UUID()
        let item = DomainFixtures.makeActiveExercise(
            exercise: Self.bench,
            sets: [
                DomainFixtures.makeSet(workoutExerciseId: workoutExerciseId, position: 0, kilograms: 40, reps: 10, isWarmup: true),
                DomainFixtures.makeSet(workoutExerciseId: workoutExerciseId, position: 1, kilograms: 60, reps: 8),
                DomainFixtures.makeSet(workoutExerciseId: workoutExerciseId, position: 2, kilograms: 65, reps: 6),
            ]
        )
        let entry = WorkoutSetPlanner.newSet(in: item, isWarmup: false)
        #expect(Self.values([entry]) == ["65.0×6/-"])
        #expect(entry.position == 3)
        #expect(entry.state == .planned)
        #expect(entry.workoutExerciseId == workoutExerciseId)
    }

    @Test func newWarmupGoesBeforeWorkingSets() {
        let workoutExerciseId = UUID()
        let item = DomainFixtures.makeActiveExercise(
            exercise: Self.bench,
            sets: [
                DomainFixtures.makeSet(workoutExerciseId: workoutExerciseId, position: 0, kilograms: 60, reps: 8),
                DomainFixtures.makeSet(workoutExerciseId: workoutExerciseId, position: 1, kilograms: 60, reps: 8),
            ]
        )
        let warmup = WorkoutSetPlanner.newSet(in: item, isWarmup: true)
        #expect(warmup.isWarmup)
        #expect(warmup.position == 0)
        #expect(Self.values([warmup]) == ["20.0×8/-"])
    }

    @Test func firstWorkingSetFallsBackToPreviousWorkout() {
        let item = DomainFixtures.makeActiveExercise(
            exercise: Self.bench,
            sets: [],
            previousSets: [
                DomainFixtures.makeSet(position: 0, kilograms: 30, reps: 12, isWarmup: true),
                DomainFixtures.makeSet(position: 1, kilograms: 55, reps: 9),
            ]
        )
        let entry = WorkoutSetPlanner.newSet(in: item, isWarmup: false)
        #expect(Self.values([entry]) == ["55.0×9/-"])
        #expect(entry.position == 0)
    }

    @Test func firstWorkoutUsesTheStartWeightAndTargetDuration() {
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: 2,
            targetReps: RepRange(min: 8, max: 12),
            startWeight: Weight(kilograms: 40),
            previousSets: []
        )
        #expect(Self.values(sets) == ["40.0×8/-", "40.0×8/-"])
        let timed = WorkoutSetPlanner.plannedSets(
            for: Self.plank,
            workoutExerciseId: UUID(),
            targetSets: 2,
            targetReps: nil,
            targetDurationSeconds: 75,
            previousSets: []
        )
        #expect(Self.values(timed) == ["0.0×-/75", "0.0×-/75"])
    }

    @Test func historyWinsOverTheStartWeight() {
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: 1,
            targetReps: RepRange(min: 8, max: 12),
            startWeight: Weight(kilograms: 40),
            previousSets: [DomainFixtures.makeSet(position: 0, kilograms: 55, reps: 9)]
        )
        #expect(Self.values(sets) == ["55.0×9/-"])
    }

    @Test func startWeightBelowTheBarFallsBackToTheBar() {
        let sets = WorkoutSetPlanner.plannedSets(
            for: Self.bench,
            workoutExerciseId: UUID(),
            targetSets: 1,
            targetReps: RepRange(min: 8, max: 12),
            startWeight: Weight(kilograms: 10),
            previousSets: []
        )
        #expect(Self.values(sets) == ["20.0×8/-"])
    }
}
