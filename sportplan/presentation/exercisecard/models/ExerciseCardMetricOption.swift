import Domain

struct ExerciseCardMetricOption: Identifiable, Hashable {
    let metric: ProgressMetric
    let title: String

    var id: ProgressMetric {
        return metric
    }
}
