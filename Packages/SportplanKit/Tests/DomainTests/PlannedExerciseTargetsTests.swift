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
}
