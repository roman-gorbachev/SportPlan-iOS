import Domain

struct ActiveWorkoutSnapshot: Sendable {
    let state: ActiveWorkoutStoreState
    let rest: RestPeriod?
}
