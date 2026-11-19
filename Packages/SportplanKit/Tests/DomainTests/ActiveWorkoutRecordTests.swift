import Domain
import Foundation
import Testing

struct ActiveWorkoutRecordTests {
    @Test func activeExerciseMarksSetsAgainstEarlierWorkouts() {
        let exercise = DomainFixtures.makeLibraryExercise()
        let baseline = RecordBaseline(sets: [RecordFixtures.set(kilograms: 60, reps: 8, at: RecordFixtures.day(0))])
        let equal = RecordFixtures.set(kilograms: 60, reps: 8, at: RecordFixtures.day(7), position: 0)
        let heavier = RecordFixtures.set(kilograms: 62.5, reps: 8, at: RecordFixtures.day(7).addingTimeInterval(120), position: 1)
        let planned = DomainFixtures.makeSet(position: 2, kilograms: 70, reps: 8, completedAt: nil)
        let workoutExercise = WorkoutExercise(
            id: UUID(),
            workoutId: UUID(),
            exerciseId: exercise.id,
            position: 0,
            targetSets: 3,
            targetReps: nil,
            restSeconds: Exercise.defaultRestSeconds
        )

        let active = ActiveWorkoutExercise(
            workoutExercise: workoutExercise,
            exercise: exercise,
            sets: [equal, heavier, planned],
            previousSets: [],
            recordBaseline: baseline
        )

        #expect(active.recordSetIds == [heavier.id])
    }
}
