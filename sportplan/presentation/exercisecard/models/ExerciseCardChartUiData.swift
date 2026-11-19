struct ExerciseCardChartUiData: Hashable {
    let caption: String
    let value: String
    let unit: String
    let delta: String?
    let isDeltaPositive: Bool
    let valueKind: ExerciseCardValueKind
    let points: [ExerciseCardChartPoint]
    let accessibilityLabel: String
}
