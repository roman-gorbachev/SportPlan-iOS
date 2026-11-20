import Domain
import Foundation
import Observation

@Observable
final class WorkoutPreviewViewModel {
    @ObservationIgnored private let dayId: UUID
    @ObservationIgnored private let loadWorkoutPreview: LoadWorkoutPreviewUseCase
    @ObservationIgnored private let startWorkoutFromDay: StartWorkoutFromDayUseCase
    @ObservationIgnored private var preview: WorkoutPreview?
    @ObservationIgnored private var isStarting = false
    @ObservationIgnored private var isShowingError = false

    private(set) var previewUiState: WorkoutPreviewUiState = .loading

    init(dayId: UUID, loadWorkoutPreview: LoadWorkoutPreviewUseCase, startWorkoutFromDay: StartWorkoutFromDayUseCase) {
        self.dayId = dayId
        self.loadWorkoutPreview = loadWorkoutPreview
        self.startWorkoutFromDay = startWorkoutFromDay
    }

    func load() async {
        do {
            preview = try await loadWorkoutPreview.execute(dayId: dayId)
            publish()
        } catch {
            guard !Task.isCancelled else {
                return
            }
            previewUiState = .error(error: error)
        }
    }

    func start() async -> Bool {
        guard !isStarting else {
            return false
        }
        isStarting = true
        publish()
        let didStart: Bool
        do {
            try await startWorkoutFromDay.execute(dayId: dayId)
            didStart = true
        } catch {
            isShowingError = true
            didStart = false
        }
        isStarting = false
        publish()
        return didStart
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func publish() {
        guard let preview else {
            return
        }
        previewUiState = .success(data: WorkoutPreviewMapper.makeData(
            preview,
            isStarting: isStarting,
            isShowingError: isShowingError
        ))
    }
}
