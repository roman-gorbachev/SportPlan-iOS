import Foundation
import Testing
import WorkoutActivity

struct WorkoutActivityDisplayStateTests {
    private static let restStart = Date(timeIntervalSince1970: 1_000)
    private static let restEnd = Date(timeIntervalSince1970: 1_120)

    @Test
    func setPhaseShowsTheSet() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .set, rest: nil), isStale: true)
        #expect(state == .set)
    }

    @Test
    func restPhaseCountsDownUntilStale() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .rest, rest: (Self.restStart, Self.restEnd)), isStale: false)
        #expect(state == .rest(interval: Self.restStart...Self.restEnd))
    }

    @Test
    func staleRestShowsThatRestIsOver() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .rest, rest: (Self.restStart, Self.restEnd)), isStale: true)
        #expect(state == .restOver(endedAt: Self.restEnd))
    }

    @Test
    func restWithoutDatesFallsBackToTheSet() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .rest, rest: nil), isStale: false)
        #expect(state == .set)
    }

    @Test
    func restEndingBeforeItsStartDoesNotBuildAnInvalidRange() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .rest, rest: (Self.restEnd, Self.restStart)), isStale: false)
        #expect(state == .rest(interval: Self.restStart...Self.restStart))
    }

    @Test
    func finishedSetsStayFinished() {
        let state = WorkoutActivityDisplayState(content: Self.content(phase: .finishedSets, rest: nil), isStale: false)
        #expect(state == .finishedSets)
    }

    private static func content(phase: WorkoutActivityPhase, rest: (Date, Date)?) -> WorkoutActivityContent {
        return WorkoutActivityContent(
            phase: phase,
            exerciseName: "Squat",
            setText: "set 1",
            loadText: "60 × 8",
            nextText: "next 60 × 8",
            readyText: "ready",
            restStartedAt: rest?.0,
            restEndsAt: rest?.1,
            plates: []
        )
    }
}
