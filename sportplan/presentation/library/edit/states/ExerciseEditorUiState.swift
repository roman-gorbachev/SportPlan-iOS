enum ExerciseEditorUiState {
    case loading
    case success(data: ExerciseEditorUiData)
    case error(error: any Error)
}
