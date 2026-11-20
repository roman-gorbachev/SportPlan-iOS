import Domain
import Foundation
import Testing

struct HeatmapBuilderTests {
    private let exercise = DomainFixtures.makeLibraryExercise()
    private let today = DomainFixtures.referenceDate

    @Test(arguments: [
        (0, HeatmapLevel.rest),
        (1, .light),
        (6, .light),
        (7, .moderate),
        (12, .moderate),
        (13, .high),
        (18, .high),
        (19, .peak),
        (40, .peak),
    ])
    func levelFollowsWorkingSetThresholds(count: Int, level: HeatmapLevel) {
        #expect(HeatmapLevel(workingSetCount: count) == level)
    }

    @Test func gridCoversFifteenWeeksStartingOnMonday() {
        let calendar = HistoryFixtures.calendar
        let heatmap = HeatmapBuilder.make(workouts: [], today: today, calendar: calendar)

        #expect(heatmap.weeks.count == HeatmapBuilder.weekCount)
        #expect(heatmap.weeks.allSatisfy { week in return week.days.count == 7 })
        #expect(heatmap.weeks.allSatisfy { week in return calendar.component(.weekday, from: week.start) == HeatmapBuilder.mondayWeekday })
        let days = heatmap.weeks.flatMap(\.days)
        let todayIndex = days.firstIndex { day in return day.isToday }
        #expect(todayIndex != nil)
        #expect(todayIndex.map { index in return days[index].date } == calendar.startOfDay(for: today))
        #expect(days.filter(\.isFuture).allSatisfy { day in return day.date > today })
        #expect(days.prefix(while: { day in return !day.isToday }).allSatisfy { day in return !day.isFuture })
    }

    @Test func dayAddsWorkingSetsOfAllItsWorkoutsWithoutWarmups() {
        let calendar = HistoryFixtures.calendar
        let morning = calendar.startOfDay(for: today).addingTimeInterval(HistoryFixtures.secondsPerHour)
        let first = HistoryFixtures.workout(
            exercise: exercise,
            startedAt: morning,
            sets: [(kilograms: 40, reps: 10, isWarmup: true)] + HistoryFixtures.working(4)
        )
        let second = HistoryFixtures.workout(
            exercise: exercise,
            startedAt: morning.addingTimeInterval(HistoryFixtures.secondsPerHour * 3),
            sets: HistoryFixtures.working(3)
        )

        let heatmap = HeatmapBuilder.make(workouts: [second, first], today: today, calendar: calendar)
        let day = heatmap.day(containing: calendar.startOfDay(for: today))

        #expect(day?.workingSetCount == 7)
        #expect(day?.level == .moderate)
        #expect(day?.workoutIds == [first.id, second.id])
        #expect(heatmap.workoutCount == 2)
    }

    @Test func workoutsBeforeTheWindowAreLeftOut() {
        let calendar = HistoryFixtures.calendar
        let longAgo = calendar.date(byAdding: .weekOfYear, value: -HeatmapBuilder.weekCount, to: today) ?? today
        let old = HistoryFixtures.workout(exercise: exercise, startedAt: longAgo, sets: HistoryFixtures.working(5))

        let heatmap = HeatmapBuilder.make(workouts: [old], today: today, calendar: calendar)

        #expect(heatmap.workoutCount == 0)
        #expect(heatmap.weeks.flatMap(\.days).allSatisfy { day in return day.level == .rest })
    }
}
