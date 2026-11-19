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
    private let observePlates: ObservePlatesUseCase
    private let controller: any WorkoutActivityController
    private var shown: Shown = .unknown
    private var isObserving = false

    init(store: ActiveWorkoutStore, observePlates: ObservePlatesUseCase, controller: any WorkoutActivityController) {
        self.store = store
        self.observePlates = observePlates
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
        let plateSet = ObservedPlateSet()
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.follow(plateSet)
            }
            group.addTask {
                await self.applyChanges(plateSet)
            }
        }
    }

    private func follow(_ plateSet: ObservedPlateSet) async {
        do {
            for try await plates in observePlates.execute() {
                plateSet.plates = plates
            }
        } catch {
            guard !Task.isCancelled, plateSet.plates == nil else {
                return
            }
            plateSet.plates = []
        }
    }

    private func applyChanges(_ plateSet: ObservedPlateSet) async {
        let store = store
        let changes = Observations {
            return ObservedChange(snapshot: store.snapshot, plates: plateSet.plates)
        }
        for await change in changes {
            guard let plates = change.plates else {
                continue
            }
            await apply(change.snapshot, plates: plates)
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

@Observable
private final class ObservedPlateSet {
    var plates: [Plate]?
}

private struct ObservedChange: Sendable {
    let snapshot: ActiveWorkoutSnapshot
    let plates: [Plate]?
}
