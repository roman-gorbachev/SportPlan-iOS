import Domain
import Foundation

extension PersonalRecordKind {
    var title: String {
        switch self {
        case .maxWeight:
            return String(localized: "exerciseCard.metric.maxWeight")
        case .estimatedOneRepMax:
            return String(localized: "exerciseCard.metric.oneRepMax")
        case .maxReps:
            return String(localized: "exerciseCard.metric.maxReps")
        case .maxWeightedReps:
            return String(localized: "exerciseCard.record.maxWeighted")
        case .maxDuration:
            return String(localized: "exerciseCard.metric.maxDuration")
        }
    }
}
