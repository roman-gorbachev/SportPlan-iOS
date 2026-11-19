import Domain

struct ExerciseCardUiData: Hashable {
    let name: String
    let meta: String
    let metricOptions: [ExerciseCardMetricOption]
    let selectedMetric: ProgressMetric
    let chart: ExerciseCardChartUiData
    let hasData: Bool
    let chartPlaceholder: String
    let records: [ExerciseCardRecordItem]
    let sessions: [ExerciseCardSessionItem]

    var showsMetricPicker: Bool {
        return metricOptions.count > 1
    }
}
