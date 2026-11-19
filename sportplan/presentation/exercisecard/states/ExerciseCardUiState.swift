enum ExerciseCardUiState {
    case loading
    case success(data: ExerciseCardUiData)
    case error(error: any Error)
}
