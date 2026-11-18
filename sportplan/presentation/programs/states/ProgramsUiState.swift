enum ProgramsUiState {
    case loading
    case success(data: ProgramsUiData)
    case error(error: any Error)
}
