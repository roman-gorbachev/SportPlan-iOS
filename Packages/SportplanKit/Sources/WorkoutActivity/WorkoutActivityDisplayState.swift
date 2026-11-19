import Foundation

public enum WorkoutActivityDisplayState: Hashable, Sendable {
    case set
    case rest(interval: ClosedRange<Date>)
    case restOver(endedAt: Date)
    case finishedSets

    public init(content: WorkoutActivityContent, isStale: Bool) {
        switch content.phase {
        case .set:
            self = .set
        case .finishedSets:
            self = .finishedSets
        case .rest:
            guard let startedAt = content.restStartedAt, let endsAt = content.restEndsAt else {
                self = .set
                return
            }
            if isStale {
                self = .restOver(endedAt: endsAt)
            } else {
                self = .rest(interval: min(startedAt, endsAt)...endsAt)
            }
        }
    }
}
