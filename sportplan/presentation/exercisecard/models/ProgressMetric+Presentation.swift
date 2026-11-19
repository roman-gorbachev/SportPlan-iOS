import Domain
import Foundation

extension ProgressMetric {
    var title: String {
        switch self {
        case .estimatedOneRepMax:
            return String(localized: "exerciseCard.metric.oneRepMax")
        case .maxWeight:
            return String(localized: "exerciseCard.metric.maxWeight")
        case .maxReps:
            return String(localized: "exerciseCard.metric.maxReps")
        case .maxDuration:
            return String(localized: "exerciseCard.metric.maxDuration")
        }
    }

    var valueKind: ExerciseCardValueKind {
        switch self {
        case .estimatedOneRepMax, .maxWeight:
            return .kilograms
        case .maxReps:
            return .reps
        case .maxDuration:
            return .duration
        }
    }
}
