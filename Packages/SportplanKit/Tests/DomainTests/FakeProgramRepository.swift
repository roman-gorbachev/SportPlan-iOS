import Domain
import Foundation
import Synchronization

final class FakeProgramRepository: ProgramRepository {
    private struct State {
        var programs: [Program] = []
        var days: [ProgramDay] = []
        var plannedExercises: [PlannedExercise] = []
        var dayDetails: [UUID: ProgramDayDetail] = [:]
    }

    private let state = Mutex(State())

    init(days: [ProgramDay] = [], plannedExercises: [PlannedExercise] = [], dayDetails: [ProgramDayDetail] = []) {
        state.withLock { state in
            state.days = days
            state.plannedExercises = plannedExercises
            for detail in dayDetails {
                state.dayDetails[detail.day.id] = detail
            }
        }
    }

    var programs: [Program] {
        return state.withLock { state in
            return state.programs
        }
    }

    var days: [ProgramDay] {
        return state.withLock { state in
            return state.days
        }
    }

    var plannedExercises: [PlannedExercise] {
        return state.withLock { state in
            return state.plannedExercises
        }
    }

    func observePrograms() -> AsyncThrowingStream<[ProgramSummary], any Error> {
        let summaries = state.withLock { state in
            return state.programs.map { program in
                let days = state.days.filter { day in
                    return day.programId == program.id
                }.map { day in
                    let names = state.plannedExercises.filter { planned in
                        return planned.programDayId == day.id
                    }.map { planned in
                        return planned.exerciseId.uuidString
                    }
                    return ProgramDaySummary(day: day, exerciseNames: names, lastWorkoutAt: nil)
                }
                return ProgramSummary(program: program, days: days)
            }
        }
        return AsyncThrowingStream { continuation in
            continuation.yield(summaries)
            continuation.finish()
        }
    }

    func observeDay(id: UUID) -> AsyncThrowingStream<ProgramDayDetail?, any Error> {
        return AsyncThrowingStream { continuation in
            continuation.yield(nil)
            continuation.finish()
        }
    }

    func day(id: UUID) async throws -> ProgramDayDetail? {
        return state.withLock { state in
            return state.dayDetails[id]
        }
    }

    func createProgram(_ program: Program, firstDay: ProgramDay) async throws -> Program {
        state.withLock { state in
            state.programs.append(program)
            state.days.append(firstDay)
        }
        return program
    }

    func renameProgram(id: UUID, name: String) async throws {
        try state.withLock { state in
            guard let index = state.programs.firstIndex(where: { program in return program.id == id }) else {
                throw ProgramError.notFound
            }
            state.programs[index].name = name
        }
    }

    func deleteProgram(id: UUID) async throws {
        state.withLock { state in
            state.programs.removeAll { program in
                return program.id == id
            }
        }
    }

    func addDay(_ day: ProgramDay) async throws -> ProgramDay {
        state.withLock { state in
            state.days.append(day)
        }
        return day
    }

    func updateDay(id: UUID, name: String, label: String?) async throws {
        try state.withLock { state in
            guard let index = state.days.firstIndex(where: { day in return day.id == id }) else {
                throw ProgramError.notFound
            }
            state.days[index].name = name
            state.days[index].label = label
        }
    }

    func deleteDay(id: UUID) async throws {
        state.withLock { state in
            state.days.removeAll { day in
                return day.id == id
            }
        }
    }

    func plannedExercise(id: UUID) async throws -> PlannedExercise? {
        return state.withLock { state in
            return state.plannedExercises.first { planned in
                return planned.id == id
            }
        }
    }

    func addPlannedExercise(_ plannedExercise: PlannedExercise) async throws -> PlannedExercise {
        state.withLock { state in
            state.plannedExercises.append(plannedExercise)
        }
        return plannedExercise
    }

    func updateTargets(plannedExerciseId: UUID, targets: PlannedExerciseTargets) async throws {
        try state.withLock { state in
            guard let index = state.plannedExercises.firstIndex(where: { planned in return planned.id == plannedExerciseId }) else {
                throw ProgramError.notFound
            }
            state.plannedExercises[index].targetSets = targets.sets
            state.plannedExercises[index].targetReps = targets.reps
            state.plannedExercises[index].restSeconds = targets.restSeconds
        }
    }

    func removePlannedExercise(id: UUID) async throws {
        state.withLock { state in
            state.plannedExercises.removeAll { planned in
                return planned.id == id
            }
        }
    }

    func reorderPlannedExercises(dayId: UUID, orderedIds: [UUID]) async throws {
        state.withLock { state in
            for (position, id) in orderedIds.enumerated() {
                guard let index = state.plannedExercises.firstIndex(where: { planned in return planned.id == id }) else {
                    continue
                }
                state.plannedExercises[index].position = position
            }
        }
    }
}
