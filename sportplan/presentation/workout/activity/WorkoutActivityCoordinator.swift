import Domain
import Foundation
import Observation
import WorkoutActivity

final class WorkoutActivityCoordinator {
    private enum Shown: Equatable {
        case unknown
        case ended
        case showing(attributes: WorkoutActivityAttributes, content: WorkoutActivityContent, staleDate: Date?)
    }

    private let store: ActiveWorkoutStore
    private let loadPlates: LoadPlatesUseCase
    private let controller: any WorkoutActivityController
    private var shown: Shown = .unknown
    private var isObserving = false

    init(store: ActiveWorkoutStore, loadPlates: LoadPlatesUseCase, controller: any WorkoutActivityController) {
        self.store = store
        self.loadPlates = loadPlates
        self.controller = controller
    }

    func observe() async {
        guard !isObserving else {
            return
        }
        isObserving = true
        defer {
            isObserving = false
        }
        let plates = (try? await loadPlates.execute()) ?? []
        let store = store
        let snapshots = Observations {
            return store.snapshot
        }
        for await snapshot in snapshots {
            await apply(snapshot, plates: plates)
        }
    }

    private func apply(_ snapshot: ActiveWorkoutSnapshot, plates: [Plate]) async {
        switch snapshot.state {
        case let .active(workout):
            let next = Shown.showing(
                attributes: WorkoutActivityMapper.makeAttributes(workout: workout),
                content: WorkoutActivityMapper.makeContent(workout: workout, rest: snapshot.rest, plates: plates),
                staleDate: WorkoutActivityMapper.staleDate(rest: snapshot.rest)
            )
            guard next != shown, case let .showing(attributes, content, staleDate) = next else {
                return
            }
            shown = next
            await controller.show(attributes: attributes, content: content, staleDate: staleDate)
        case .noWorkout:
            guard shown != .ended else {
                return
            }
            shown = .ended
            await controller.end()
        case .loading, .error:
            return
        }
    }
}
