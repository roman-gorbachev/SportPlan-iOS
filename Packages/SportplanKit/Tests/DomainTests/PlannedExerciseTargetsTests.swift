import Domain
import Testing

struct PlannedExerciseTargetsTests {
    private static let restSeconds = 120

    @Test func defaultsForRepetitionsAreThreeSetsOfEightToTwelve() throws {
        var exercise = DomainFixtures.makeExercise(name: "Жим лёжа", load: .bodyweight)
        exercise.restSeconds = Self.restSeconds
        let targets = PlannedExerciseTargets(defaultsFor: exercise)
        #expect(targets.sets == 3)
        #expect(targets.reps == RepRange(min: 8, max: 12))
        #expect(targets.restSeconds == Self.restSeconds)
        #expect(targets.validationIssues(for: .weightReps).isEmpty)
    }

    @Test func defaultsForDurationHaveNoReps() {
        let exercise = DomainFixtures.makeExercise(name: "Планка", load: .bodyweight, metric: .duration)
        let targets = PlannedExerciseTargets(defaultsFor: exercise)
        #expect(targets.reps == nil)
        #expect(targets.validationIssues(for: .duration).isEmpty)
    }

    @Test func setsMustStayWithinBounds() {
        let reps = RepRange(min: 8, max: 12)
        #expect(PlannedExerciseTargets(sets: 0, reps: reps, restSeconds: 90).validationIssues(for: .weightReps) == [.setsOutOfRange])
        #expect(PlannedExerciseTargets(sets: 11, reps: reps, restSeconds: 90).validationIssues(for: .weightReps) == [.setsOutOfRange])
        #expect(PlannedExerciseTargets(sets: 10, reps: reps, restSeconds: 90).validationIssues(for: .weightReps).isEmpty)
    }

    @Test func repsDependOnMetric() {
        let reps = RepRange(min: 8, max: 12)
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90).validationIssues(for: .weightReps) == [.missingReps])
        #expect(PlannedExerciseTargets(sets: 3, reps: reps, restSeconds: 90).validationIssues(for: .duration) == [.repsNotAllowed])
        #expect(PlannedExerciseTargets(sets: 3, reps: RepRange(min: 5, max: 101), restSeconds: 90).validationIssues(for: .weightReps) == [.repsOutOfRange])
    }

    @Test func restMustStayWithinExerciseBounds() {
        let tooLong = Exercise.maximumRestSeconds + Exercise.restStepSeconds
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: tooLong).validationIssues(for: .duration) == [.restOutOfRange])
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: -1).validationIssues(for: .duration) == [.restOutOfRange])
    }

    @Test func setsStepperStopsAtBounds() {
        var targets = PlannedExerciseTargets(sets: 1, reps: nil, restSeconds: 90)
        #expect(targets.canDecrementSets == false)
        targets.decrementSets()
        #expect(targets.sets == 1)
        targets = PlannedExerciseTargets(sets: 10, reps: nil, restSeconds: 90)
        #expect(targets.canIncrementSets == false)
        targets.incrementSets()
        #expect(targets.sets == 10)
    }

    @Test func repBoundsPullEachOther() {
        var targets = PlannedExerciseTargets(sets: 3, reps: RepRange(min: 8, max: 8), restSeconds: 90)
        targets.incrementMinimumReps()
        #expect(targets.reps == RepRange(min: 9, max: 9))
        targets.decrementMaximumReps()
        #expect(targets.reps == RepRange(min: 8, max: 8))
        targets.incrementMaximumReps()
        #expect(targets.reps == RepRange(min: 8, max: 9))
    }

    @Test func repsStepperStopsAtBounds() {
        var targets = PlannedExerciseTargets(sets: 3, reps: RepRange(min: 1, max: 100), restSeconds: 90)
        #expect(targets.canDecrementMinimumReps == false)
        #expect(targets.canIncrementMaximumReps == false)
        targets.decrementMinimumReps()
        targets.incrementMaximumReps()
        #expect(targets.reps == RepRange(min: 1, max: 100))
    }

    @Test func durationTargetsHaveNoRepSteps() {
        var targets = PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90)
        #expect(targets.canIncrementMinimumReps == false)
        targets.incrementMinimumReps()
        #expect(targets.reps == nil)
    }

    @Test func restStepsByFifteenSeconds() {
        var targets = PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: Exercise.maximumRestSeconds)
        #expect(targets.canIncrementRest == false)
        targets.decrementRest()
        #expect(targets.restSeconds == Exercise.maximumRestSeconds - Exercise.restStepSeconds)
    }

    @Test func durationDefaultsToOneMinuteAndStepsByFiveSeconds() {
        var targets = PlannedExerciseTargets(defaultsFor: .duration, restSeconds: 60)
        #expect(targets.durationSeconds == 60)
        targets.incrementDuration()
        #expect(targets.durationSeconds == 65)
        targets = PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 60, durationSeconds: 5)
        #expect(targets.canDecrementDuration == false)
        targets.decrementDuration()
        #expect(targets.durationSeconds == 5)
        targets = PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 60, durationSeconds: 600)
        #expect(targets.canIncrementDuration == false)
    }

    @Test func durationAndStartWeightDependOnMetric() {
        let reps = RepRange(min: 8, max: 12)
        let weight = Weight(kilograms: 40)
        #expect(PlannedExerciseTargets(sets: 3, reps: reps, restSeconds: 90, startWeight: weight).validationIssues(for: .weightReps).isEmpty)
        #expect(PlannedExerciseTargets(sets: 3, reps: reps, restSeconds: 90, durationSeconds: 60).validationIssues(for: .weightReps) == [.durationNotAllowed])
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90, startWeight: weight).validationIssues(for: .duration) == [.startWeightNotAllowed])
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90, durationSeconds: 4).validationIssues(for: .duration) == [.durationOutOfRange])
        #expect(PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90, durationSeconds: 601).validationIssues(for: .duration) == [.durationOutOfRange])
        #expect(PlannedExerciseTargets(sets: 3, reps: reps, restSeconds: 90, startWeight: .zero).validationIssues(for: .weightReps) == [.startWeightOutOfRange])
    }

    @Test func normalizedKeepsOnlyTheFieldsOfTheMetric() {
        let mixed = PlannedExerciseTargets(sets: 3, reps: nil, restSeconds: 90, startWeight: Weight(kilograms: 40), durationSeconds: nil)
        let timed = mixed.normalized(for: .duration)
        #expect(timed.startWeight == nil)
        #expect(timed.durationSeconds == PlannedExerciseTargets.defaultDurationSeconds)
        #expect(timed.validationIssues(for: .duration).isEmpty)
        let lifted = timed.normalized(for: .weightReps)
        #expect(lifted.durationSeconds == nil)
        #expect(lifted.reps == RepRange(min: 8, max: 12))
    }

    @Test func startWeightStepsByTheEquipmentFromTheBar() {
        let scale = DomainFixtures.makeLibraryExercise().weightScale
        var targets = PlannedExerciseTargets(sets: 3, reps: RepRange(min: 8, max: 12), restSeconds: 90)
        #expect(targets.startWeight(on: scale) == Weight(kilograms: 20))
        #expect(targets.canDecrementStartWeight(on: scale) == false)
        targets.incrementStartWeight(on: scale)
        targets.incrementStartWeight(on: scale)
        #expect(targets.startWeight == Weight(kilograms: 25))
        targets.decrementStartWeight(on: scale)
        targets.decrementStartWeight(on: scale)
        #expect(targets.startWeight == nil)
    }

    @Test func bodyweightStartWeightIsAddedWeightFromZero() {
        let scale = DomainFixtures.makeLibraryExercise(name: "Подтягивания", kind: nil).weightScale
        var targets = PlannedExerciseTargets(sets: 3, reps: RepRange(min: 5, max: 8), restSeconds: 90)
        #expect(scale.isAddedWeight)
        #expect(targets.startWeight(on: scale) == .zero)
        targets.incrementStartWeight(on: scale)
        #expect(targets.startWeight == Weight(kilograms: 2.5))
    }
}
