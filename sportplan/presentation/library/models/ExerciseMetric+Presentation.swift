import Domain
import Foundation

extension ExerciseMetric {
    var title: String {
        switch self {
        case .weightReps:
            return String(localized: "exercise.metric.reps")
        case .duration:
            return String(localized: "exercise.metric.duration")
        }
    }

    var listTitle: String {
        switch self {
        case .weightReps:
            return String(localized: "exercise.metric.reps.list")
        case .duration:
            return String(localized: "exercise.metric.duration.list")
        }
    }
}
