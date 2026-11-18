enum ProgramFormUiState {
    case loading
    case success(data: ProgramFormUiData)
    case error(error: any Error)
}
