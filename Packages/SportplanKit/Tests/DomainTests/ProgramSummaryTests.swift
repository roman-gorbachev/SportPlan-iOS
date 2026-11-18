import Domain
import Foundation
import Testing

struct ProgramSummaryTests {
    private static let programId = UUID()

    private static func makeSummary(lastWorkoutDays: [Int?]) -> ProgramSummary {
        let program = Program(id: programId, name: "Сила 3×", position: 0, createdAt: DomainFixtures.referenceDate)
        let labels = ["A", "B", "C"]
        let days = lastWorkoutDays.enumerated().map { position, dayOffset in
            let day = ProgramDay(id: UUID(), programId: programId, name: "День", label: labels[position], position: position)
            let date = dayOffset.map { offset in
                return DomainFixtures.referenceDate.addingTimeInterval(TimeInterval(offset * 86_400))
            }
            return ProgramDaySummary(day: day, exerciseNames: [], lastWorkoutAt: date)
        }
        return ProgramSummary(program: program, days: days)
    }

    @Test func withoutHistoryTheFirstDayIsNext() {
        #expect(Self.makeSummary(lastWorkoutDays: [nil, nil, nil]).nextDay?.day.label == "A")
    }

    @Test func dayAfterTheLatestWorkoutIsNext() {
        #expect(Self.makeSummary(lastWorkoutDays: [1, 3, nil]).nextDay?.day.label == "C")
        #expect(Self.makeSummary(lastWorkoutDays: [5, 3, nil]).nextDay?.day.label == "B")
    }

    @Test func nextDayWrapsAroundAfterTheLastDay() {
        #expect(Self.makeSummary(lastWorkoutDays: [1, 2, 3]).nextDay?.day.label == "A")
    }

    @Test func programWithoutDaysHasNoNextDay() {
        #expect(Self.makeSummary(lastWorkoutDays: []).nextDay == nil)
    }
}
