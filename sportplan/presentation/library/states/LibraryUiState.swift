enum LibraryUiState {
    case loading
    case success(data: LibraryUiData)
    case error(error: any Error)
}
