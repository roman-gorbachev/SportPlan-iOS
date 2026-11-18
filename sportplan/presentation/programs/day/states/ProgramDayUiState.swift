enum ProgramDayUiState {
    case loading
    case success(data: ProgramDayUiData)
    case missing
    case error(error: any Error)
}
