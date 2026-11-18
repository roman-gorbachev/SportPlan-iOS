enum GymUiState {
    case loading
    case success(data: GymUiData)
    case error(error: any Error)
}
