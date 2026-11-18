import Domain
import Foundation
import Observation

@Observable
final class ActiveWorkoutStore {
    private static let finishAlertTolerance: TimeInterval = 2

    @ObservationIgnored private let observeActiveWorkout: ObserveActiveWorkoutUseCase
    @ObservationIgnored private var restEndTask: Task<Void, Never>?
    @ObservationIgnored private var isObserving = false

    private(set) var state: ActiveWorkoutStoreState = .loading
    private(set) var rest: RestPeriod?
    private(set) var restFinishedCount = 0

    init(observeActiveWorkout: ObserveActiveWorkoutUseCase) {
        self.observeActiveWorkout = observeActiveWorkout
    }

    var snapshot: ActiveWorkoutSnapshot {
        return ActiveWorkoutSnapshot(state: state, rest: rest)
    }

    func observe() async {
        guard !isObserving else {
            return
        }
        isObserving = true
        defer {
            isObserving = false
        }
        do {
            for try await workout in observeActiveWorkout.execute() {
                state = workout.map { workout in
                    return ActiveWorkoutStoreState.active(workout: workout)
                } ?? .noWorkout
                updateRest(workout?.workout.rest)
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            state = .error(error: error)
            updateRest(nil)
        }
    }

    private func updateRest(_ period: RestPeriod?) {
        let active = period.flatMap { period in
            return period.isActive(at: Date()) ? period : nil
        }
        guard active != rest else {
            return
        }
        rest = active
        restEndTask?.cancel()
        restEndTask = nil
        guard let active else {
            return
        }
        restEndTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(active.remaining(at: Date())))
            } catch {
                return
            }
            self?.finishRest(active)
        }
    }

    private func finishRest(_ period: RestPeriod) {
        guard rest == period else {
            return
        }
        rest = nil
        restEndTask = nil
        if Date().timeIntervalSince(period.endsAt) <= Self.finishAlertTolerance {
            restFinishedCount += 1
        }
    }
}
