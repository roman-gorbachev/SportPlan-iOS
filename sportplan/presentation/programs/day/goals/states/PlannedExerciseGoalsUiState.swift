enum PlannedExerciseGoalsUiState {
    case loading
    case success(data: PlannedExerciseGoalsUiData)
    case error(error: any Error)
}
