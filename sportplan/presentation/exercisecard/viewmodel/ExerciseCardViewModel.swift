import Domain
import Foundation
import Observation

@Observable
final class ExerciseCardViewModel {
    @ObservationIgnored private let observeExerciseCard: ObserveExerciseCardUseCase
    @ObservationIgnored private let exerciseId: UUID
    @ObservationIgnored private var card: ExerciseCard?
    @ObservationIgnored private var selectedMetric: ProgressMetric?

    private(set) var exerciseCardUiState: ExerciseCardUiState = .loading

    init(observeExerciseCard: ObserveExerciseCardUseCase, exerciseId: UUID) {
        self.observeExerciseCard = observeExerciseCard
        self.exerciseId = exerciseId
    }

    func observe() async {
        do {
            for try await card in observeExerciseCard.execute(exerciseId: exerciseId) {
                self.card = card
                rebuild()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            exerciseCardUiState = .error(error: error)
        }
    }

    func selectMetric(_ metric: ProgressMetric) {
        selectedMetric = metric
        rebuild()
    }

    private func rebuild() {
        guard let card else {
            return
        }
        let available = card.series.map(\.metric)
        let metric = selectedMetric.flatMap { selected in
            return available.contains(selected) ? selected : nil
        } ?? available.first
        guard let metric else {
            return
        }
        exerciseCardUiState = .success(data: ExerciseCardUiMapper.makeData(card, selectedMetric: metric))
    }
}
