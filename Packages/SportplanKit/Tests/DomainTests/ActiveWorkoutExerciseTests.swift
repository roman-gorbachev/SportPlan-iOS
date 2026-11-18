import Domain
import Foundation
import Testing

struct ActiveWorkoutExerciseTests {
    @Test func previousResultIsMatchedByNumberWithinWarmupsAndWorkingSets() {
        let warmup = DomainFixtures.makeSet(position: 0, kilograms: 40, reps: 10, isWarmup: true, completedAt: nil)
        let first = DomainFixtures.makeSet(position: 1, kilograms: 60, reps: 8, completedAt: nil)
        let second = DomainFixtures.makeSet(position: 2, kilograms: 65, reps: 8, completedAt: nil)
        let third = DomainFixtures.makeSet(position: 3, kilograms: 65, reps: 8, completedAt: nil)
        let previousWarmup = DomainFixtures.makeSet(position: 0, kilograms: 40, reps: 12, isWarmup: true)
        let previousFirst = DomainFixtures.makeSet(position: 1, kilograms: 60, reps: 8)
        let previousSecond = DomainFixtures.makeSet(position: 2, kilograms: 62.5, reps: 8)
        let item = DomainFixtures.makeActiveExercise(
            exercise: DomainFixtures.makeLibraryExercise(),
            sets: [warmup, first, second, third],
            previousSets: [previousWarmup, previousFirst, previousSecond]
        )
        #expect(item.previousResult(for: warmup) == previousWarmup)
        #expect(item.previousResult(for: first) == previousFirst)
        #expect(item.previousResult(for: second) == previousSecond)
        #expect(item.previousResult(for: third) == nil)
    }

    @Test func setBeforeSkipsRowsOfTheOtherKind() {
        let warmup = DomainFixtures.makeSet(position: 0, kilograms: 40, reps: 10, isWarmup: true)
        let first = DomainFixtures.makeSet(position: 1, kilograms: 60, reps: 8)
        let second = DomainFixtures.makeSet(position: 2, kilograms: 65, reps: 8, completedAt: nil)
        let item = DomainFixtures.makeActiveExercise(exercise: DomainFixtures.makeLibraryExercise(), sets: [warmup, first, second])
        #expect(item.setBefore(warmup) == nil)
        #expect(item.setBefore(first) == nil)
        #expect(item.setBefore(second) == first)
        #expect(item.completedWorkingSetCount == 1)
    }

    @Test func setStateFollowsTimestamps() {
        var entry = DomainFixtures.makeSet(position: 0, kilograms: 0, reps: nil, completedAt: nil)
        #expect(entry.state == .planned)
        entry.startedAt = DomainFixtures.referenceDate
        #expect(entry.state == .running)
        entry.completedAt = DomainFixtures.referenceDate
        #expect(entry.state == .completed)
    }
}
