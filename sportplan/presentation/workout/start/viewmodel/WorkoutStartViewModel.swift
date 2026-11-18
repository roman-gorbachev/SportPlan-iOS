import Domain
import Foundation
import Observation

@Observable
final class WorkoutStartViewModel {
    @ObservationIgnored private let observePrograms: ObserveProgramsUseCase
    @ObservationIgnored private let startWorkoutFromDay: StartWorkoutFromDayUseCase
    @ObservationIgnored private let startEmptyWorkout: StartEmptyWorkoutUseCase
    @ObservationIgnored private var programs: [ProgramSummary]?
    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var isShowingError = false

    private(set) var startUiState: WorkoutStartUiState = .loading

    init(
        observePrograms: ObserveProgramsUseCase,
        startWorkoutFromDay: StartWorkoutFromDayUseCase,
        startEmptyWorkout: StartEmptyWorkoutUseCase
    ) {
        self.observePrograms = observePrograms
        self.startWorkoutFromDay = startWorkoutFromDay
        self.startEmptyWorkout = startEmptyWorkout
    }

    func observeProgramList() async {
        do {
            for try await programs in observePrograms.execute() {
                self.programs = programs
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            startUiState = .error(error: error)
        }
    }

    func start(dayId: UUID) async {
        await start {
            try await self.startWorkoutFromDay.execute(dayId: dayId)
        }
    }

    func startEmpty() async {
        await start {
            try await self.startEmptyWorkout.execute()
        }
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func start(_ operation: () async throws -> Void) async {
        guard !isStarting else {
            return
        }
        isStarting = true
        publish()
        do {
            try await operation()
        } catch {
            isShowingError = true
        }
        isStarting = false
        publish()
    }

    private func publish() {
        guard let programs else {
            return
        }
        startUiState = .success(data: WorkoutStartUiData(
            programs: Self.orderedForStart(programs).compactMap(Self.makeItem),
            isStarting: isStarting,
            isShowingError: isShowingError
        ))
    }

    private static func orderedForStart(_ programs: [ProgramSummary]) -> [ProgramSummary] {
        return programs.enumerated()
            .sorted { lhs, rhs in
                let lhsDate = lastWorkoutDate(lhs.element)
                let rhsDate = lastWorkoutDate(rhs.element)
                switch (lhsDate, rhsDate) {
                case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                    return lhsDate > rhsDate
                case (.some, nil):
                    return true
                case (nil, .some):
                    return false
                default:
                    return lhs.offset < rhs.offset
                }
            }
            .map(\.element)
    }

    private static func lastWorkoutDate(_ program: ProgramSummary) -> Date? {
        return program.days.compactMap(\.lastWorkoutAt).max()
    }

    private static func makeItem(_ program: ProgramSummary) -> WorkoutStartProgramItem? {
        guard let nextDay = program.nextDay else {
            return nil
        }
        let lastWorkout = nextDay.lastWorkoutAt.map { date in
            return String(localized: "workout.start.lastTime \(WorkoutFormatting.shortDate(date))")
        } ?? String(localized: "workout.never")
        return WorkoutStartProgramItem(
            id: program.id,
            title: String(localized: "workout.start.next \(program.program.name)"),
            nextDay: WorkoutStartNextDayItem(
                id: nextDay.id,
                label: nextDay.day.label.map(WorkoutFormatting.dayLabel),
                name: nextDay.day.name,
                exercises: WorkoutFormatting.exerciseList(nextDay.exerciseNames),
                lastWorkout: lastWorkout
            ),
            otherDays: program.days
                .filter { day in
                    return day.id != nextDay.id
                }
                .map { day in
                    return WorkoutStartDayItem(
                        id: day.id,
                        title: WorkoutFormatting.dayTitle(day.day),
                        subtitle: WorkoutFormatting.lastWorkoutText(day.lastWorkoutAt)
                    )
                }
        )
    }
}
