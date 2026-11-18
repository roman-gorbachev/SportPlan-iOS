import Domain
import Foundation
import Observation

@Observable
final class ProgramsViewModel {
    @ObservationIgnored private let observeExerciseLibrary: ObserveExerciseLibraryUseCase
    @ObservationIgnored private let observePrograms: ObserveProgramsUseCase
    @ObservationIgnored private let deleteProgram: DeleteProgramUseCase
    @ObservationIgnored private var exerciseCount: Int?
    @ObservationIgnored private var programs: [ProgramSummary]?
    @ObservationIgnored private var pendingDeletion: ProgramDeletionConfirmation?
    @ObservationIgnored private var isShowingError = false

    private(set) var programsUiState: ProgramsUiState = .loading

    init(
        observeExerciseLibrary: ObserveExerciseLibraryUseCase,
        observePrograms: ObserveProgramsUseCase,
        deleteProgram: DeleteProgramUseCase
    ) {
        self.observeExerciseLibrary = observeExerciseLibrary
        self.observePrograms = observePrograms
        self.deleteProgram = deleteProgram
    }

    func observeLibrary() async {
        do {
            for try await library in observeExerciseLibrary.execute() {
                exerciseCount = library.count
                publish()
            }
        } catch {
            fail(with: error)
        }
    }

    func observeProgramList() async {
        do {
            for try await programs in observePrograms.execute() {
                self.programs = programs
                publish()
            }
        } catch {
            fail(with: error)
        }
    }

    func requestDelete(id: UUID) {
        guard let program = programs?.first(where: { summary in return summary.id == id }) else {
            return
        }
        pendingDeletion = ProgramDeletionConfirmation(programId: id, programName: program.program.name)
        publish()
    }

    func confirmDelete(id: UUID) async {
        pendingDeletion = nil
        publish()
        do {
            try await deleteProgram.execute(id: id)
        } catch {
            isShowingError = true
            publish()
        }
    }

    func cancelDelete() {
        pendingDeletion = nil
        publish()
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func fail(with error: any Error) {
        guard !Task.isCancelled else {
            return
        }
        programsUiState = .error(error: error)
    }

    private func publish() {
        guard let exerciseCount, let programs else {
            return
        }
        programsUiState = .success(data: ProgramsUiData(
            exerciseCount: exerciseCount,
            programs: programs.map(Self.makeItem),
            pendingDeletion: pendingDeletion,
            isShowingError: isShowingError
        ))
    }

    private static func makeItem(_ summary: ProgramSummary) -> ProgramItem {
        let daySummary = summary.days.isEmpty
            ? String(localized: "programs.days.none")
            : String(localized: "programs.days.count \(summary.days.count)")
        return ProgramItem(
            id: summary.id,
            name: summary.program.name,
            summary: daySummary,
            days: summary.days.map { day in
                return ProgramDayItem(
                    id: day.id,
                    label: day.day.label,
                    name: day.day.name,
                    summary: String(localized: "programs.day.exercises \(day.exerciseCount)")
                )
            }
        )
    }
}
