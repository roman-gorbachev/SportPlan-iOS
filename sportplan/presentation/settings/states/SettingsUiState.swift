enum SettingsUiState {
    case loading
    case success(data: SettingsUiData)
    case error(error: any Error)
}
