enum PlateEditorUiState {
    case loading
    case success(data: PlateEditorUiData)
    case error(error: any Error)
}
