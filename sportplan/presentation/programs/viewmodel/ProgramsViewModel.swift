import Domain
import Foundation
import Observation

@Observable
final class ProgramsViewModel {
    @ObservationIgnored private let observeExerciseLibrary: ObserveExerciseLibraryUseCase

    private(set) var programsUiState: ProgramsUiState = .loading

    init(observeExerciseLibrary: ObserveExerciseLibraryUseCase) {
        self.observeExerciseLibrary = observeExerciseLibrary
    }

    func observe() async {
        do {
            for try await library in observeExerciseLibrary.execute() {
                programsUiState = .success(data: ProgramsUiData(exerciseCount: library.count))
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            programsUiState = .error(error: error)
        }
    }
}
