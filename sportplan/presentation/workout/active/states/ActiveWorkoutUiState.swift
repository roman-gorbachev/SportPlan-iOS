enum ActiveWorkoutUiState {
    case loading
    case noWorkout
    case success(data: ActiveWorkoutUiData)
    case error(error: any Error)
}
