enum WorkoutDetailsUiState {
    case loading
    case success(data: WorkoutDetailsUiData)
    case deleted
    case error(error: any Error)
}
