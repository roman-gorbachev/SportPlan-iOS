import Domain
import Foundation
import Observation

@Observable
final class RestTimerViewModel {
    @ObservationIgnored private let store: ActiveWorkoutStore
    @ObservationIgnored private let adjustRest: AdjustRestUseCase

    private(set) var restTimerUiState: RestTimerUiState = .idle
    private(set) var restFinishedCount = 0

    init(store: ActiveWorkoutStore, adjustRest: AdjustRestUseCase) {
        self.store = store
        self.adjustRest = adjustRest
    }

    func observe() async {
        let store = store
        let updates = Observations {
            return (snapshot: store.snapshot, finishedCount: store.restFinishedCount)
        }
        for await update in updates {
            restFinishedCount = update.finishedCount
            guard let workout = update.snapshot.state.workout, let rest = update.snapshot.rest else {
                restTimerUiState = .idle
                continue
            }
            restTimerUiState = .resting(data: RestTimerMapper.makeItem(workout: workout, rest: rest))
        }
    }

    func extendRest() async {
        try? await adjustRest.execute(seconds: RestPeriod.adjustmentStepSeconds)
    }
}
