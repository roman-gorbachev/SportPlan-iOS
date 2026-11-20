enum HistoryDayUiState {
    case loading
    case success(data: HistoryDayUiData)
    case error(error: any Error)
}
