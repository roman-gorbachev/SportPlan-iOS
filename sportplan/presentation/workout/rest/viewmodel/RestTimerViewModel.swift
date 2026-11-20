import Domain
import Foundation
import Observation

@Observable
final class RestTimerViewModel {
    @ObservationIgnored private let store: ActiveWorkoutStore
    @ObservationIgnored private let adjustRest: AdjustRestUseCase
    @ObservationIgnored private let skipRest: SkipRestUseCase

    private(set) var restTimerUiState: RestTimerUiState = .idle
    private(set) var restFinishedCount = 0

    init(store: ActiveWorkoutStore, adjustRest: AdjustRestUseCase, skipRest: SkipRestUseCase) {
        self.store = store
        self.adjustRest = adjustRest
        self.skipRest = skipRest
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

    func adjustRest(seconds: Int) async {
        try? await adjustRest.execute(seconds: seconds)
    }

    func skipRest() async {
        try? await skipRest.execute()
    }
}
