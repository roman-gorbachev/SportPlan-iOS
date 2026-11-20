enum WorkoutPreviewUiState {
    case loading
    case success(data: WorkoutPreviewUiData)
    case error(error: any Error)
}
