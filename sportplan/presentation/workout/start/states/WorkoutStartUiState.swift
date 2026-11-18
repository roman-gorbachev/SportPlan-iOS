enum WorkoutStartUiState {
    case loading
    case success(data: WorkoutStartUiData)
    case error(error: any Error)
}
