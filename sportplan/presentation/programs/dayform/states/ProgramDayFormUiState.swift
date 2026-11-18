enum ProgramDayFormUiState {
    case loading
    case success(data: ProgramDayFormUiData)
    case error(error: any Error)
}
