enum AddExerciseUiState {
    case loading
    case success(data: AddExerciseUiData)
    case error(error: any Error)
}
