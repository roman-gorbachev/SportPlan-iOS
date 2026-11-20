enum SettingsImportStep: Equatable {
    case idle
    case confirming(message: String)
    case importing
    case finished
    case failed(message: String)
}
