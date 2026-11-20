enum ExerciseArchiveUiState {
    case loading
    case success(data: ExerciseArchiveUiData)
    case error(error: any Error)
}
