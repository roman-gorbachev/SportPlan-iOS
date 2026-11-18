enum ExercisePickerUiState {
    case loading
    case success(data: ExercisePickerUiData)
    case error(error: any Error)
}
