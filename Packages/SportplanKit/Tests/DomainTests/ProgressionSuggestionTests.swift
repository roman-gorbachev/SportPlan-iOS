import Domain
import Foundation
import Testing

struct ProgressionSuggestionTests {
    private static let targetSets = 3
    private static let targetReps = RepRange(min: 8, max: 12)

    private static func previousTargets(
        exercise: LibraryExercise,
        sets: Int? = targetSets,
        reps: RepRange? = targetReps
    ) -> WorkoutExercise {
        return WorkoutExercise(
            id: UUID(),
            workoutId: UUID(),
            exerciseId: exercise.id,
            position: 0,
            targetSets: sets,
            targetReps: reps,
            restSeconds: Exercise.defaultRestSeconds
        )
    }

    private static func previousSets(_ values: [(kilograms: Double, reps: Int)]) -> [SetEntry] {
        return values.enumerated().map { position, value in
            return DomainFixtures.makeSet(position: position, kilograms: value.kilograms, reps: value.reps)
        }
    }

    private static func pendingSets(kilograms: [Double], completedCount: Int = 0) -> [SetEntry] {
        let workoutExerciseId = UUID()
        return kilograms.enumerated().map { position, value in
            return DomainFixtures.makeSet(
                workoutExerciseId: workoutExerciseId,
                position: position,
                kilograms: value,
                reps: 12,
                completedAt: position < completedCount ? DomainFixtures.referenceDate : nil
            )
        }
    }

    private static func item(
        exercise: LibraryExercise = DomainFixtures.makeLibraryExercise(),
        previous: [SetEntry],
        targets: WorkoutExercise?? = .none,
        sets: [SetEntry] = pendingSets(kilograms: [60, 60, 60])
    ) -> ActiveWorkoutExercise {
        let base = DomainFixtures.makeActiveExercise(exercise: exercise, sets: sets, previousSets: previous)
        let previousWorkoutExercise: WorkoutExercise? = targets ?? previousTargets(exercise: exercise)
        return ActiveWorkoutExercise(
            workoutExercise: base.workoutExercise,
            exercise: exercise,
            sets: sets,
            previousSets: previous,
            previousWorkoutExercise: previousWorkoutExercise
        )
    }

    @Test func completedPlanSuggestsHeaviestWorkingWeightPlusStep() {
        let previous = Self.previousSets([(60, 12), (62.5, 12), (60, 13)])

        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == Weight(kilograms: 65))
    }

    @Test func extraSetsBeyondTheTargetDoNotPreventTheSuggestion() {
        let previous = Self.previousSets([(60, 12), (60, 12), (60, 12), (60, 12)])

        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == Weight(kilograms: 62.5))
    }

    @Test func singleRepTargetUsesThatNumberAsTheTop() throws {
        let exercise = DomainFixtures.makeLibraryExercise()
        let fixedReps = try #require(RepRange(min: 5, max: 5))
        let targets = Self.previousTargets(exercise: exercise, reps: fixedReps)
        let previous = Self.previousSets([(80, 5), (80, 5), (80, 5)])

        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: exercise, previous: previous, targets: targets)) == Weight(kilograms: 82.5))
    }

    @Test func missedTopOfRangeInOneSetGivesNoSuggestion() {
        let previous = Self.previousSets([(60, 12), (60, 12), (60, 11)])

        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == nil)
    }

    @Test func fewerSetsThanTargetGiveNoSuggestion() {
        let previous = Self.previousSets([(60, 12), (60, 12)])

        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == nil)
    }

    @Test func warmupSetsCountNeitherTowardsSetsNorWeight() {
        var previous = Self.previousSets([(60, 12), (60, 12)])
        previous.append(DomainFixtures.makeSet(position: 2, kilograms: 100, reps: 12, isWarmup: true))

        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == nil)

        previous.append(DomainFixtures.makeSet(position: 3, kilograms: 60, reps: 12))
        #expect(ProgressionSuggestion.weight(for: Self.item(previous: previous)) == Weight(kilograms: 62.5))
    }

    @Test func previousWorkoutWithoutTargetsGivesNoSuggestion() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let previous = Self.previousSets([(60, 12), (60, 12), (60, 12)])
        let noTargets = Self.previousTargets(exercise: exercise, sets: nil, reps: nil)

        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: exercise, previous: previous, targets: noTargets)) == nil)
        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: exercise, previous: previous, targets: .some(nil))) == nil)
    }

    @Test func bodyweightAndTimedExercisesGetNoSuggestion() {
        let previous = Self.previousSets([(10, 12), (10, 12), (10, 12)])
        let bodyweight = DomainFixtures.makeLibraryExercise(name: "Подтягивания", kind: nil)
        let timed = DomainFixtures.makeLibraryExercise(name: "Планка", kind: .dumbbell, metric: .duration)

        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: bodyweight, previous: previous)) == nil)
        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: timed, previous: previous)) == nil)
    }

    @Test func equipmentWithoutStepGivesNoSuggestion() {
        let equipment = Equipment(
            id: UUID(),
            name: "Тренажёр",
            kind: .selectorizedMachine,
            baseWeight: .zero,
            weightStep: .zero,
            isArchived: false,
            createdAt: DomainFixtures.referenceDate
        )
        let exercise = LibraryExercise(
            exercise: DomainFixtures.makeExercise(name: "Тяга", load: .equipment(id: equipment.id)),
            equipment: equipment
        )
        let previous = Self.previousSets([(40, 12), (40, 12), (40, 12)])

        #expect(ProgressionSuggestion.weight(for: Self.item(exercise: exercise, previous: previous)) == nil)
    }

    @Test func hintIsHiddenOnceNoPendingWorkingSetIsLighter() {
        let previous = Self.previousSets([(60, 12), (60, 12), (60, 12)])

        #expect(Self.item(previous: previous).progressionWeight == Weight(kilograms: 62.5))
        #expect(Self.item(previous: previous, sets: Self.pendingSets(kilograms: [62.5, 65, 62.5])).progressionWeight == nil)
        #expect(Self.item(previous: previous, sets: Self.pendingSets(kilograms: [60, 60, 62.5], completedCount: 2)).progressionWeight == nil)
        #expect(Self.item(previous: previous, sets: Self.pendingSets(kilograms: [60, 60, 60], completedCount: 3)).progressionWeight == nil)
        #expect(Self.item(previous: previous, sets: Self.pendingSets(kilograms: [60, 60, 60], completedCount: 1)).progressionWeight == Weight(kilograms: 62.5))
    }
}
