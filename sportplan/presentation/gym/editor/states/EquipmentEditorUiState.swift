enum EquipmentEditorUiState {
    case loading
    case success(data: EquipmentEditorUiData)
    case error(error: any Error)
}
