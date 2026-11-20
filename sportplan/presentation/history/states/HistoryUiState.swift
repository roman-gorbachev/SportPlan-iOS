enum HistoryUiState {
    case loading
    case success(data: HistoryUiData)
    case error(error: any Error)
}
