import Foundation

public enum WorkoutActivityDisplayState: Hashable, Sendable {
    case set
    case rest(interval: ClosedRange<Date>)
    case restOver(endedAt: Date)
    case finishedSets
    case timedSet(interval: ClosedRange<Date>)
    case timedSetOver(endedAt: Date)
    case timedSetRunning(startedAt: Date)

    public init(content: WorkoutActivityContent, isStale: Bool) {
        switch content.phase {
        case .set:
            self = .set
        case .finishedSets:
            self = .finishedSets
        case .timedSet:
            self = Self.timedSet(content: content, isStale: isStale)
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

    private static func timedSet(content: WorkoutActivityContent, isStale: Bool) -> WorkoutActivityDisplayState {
        guard let startedAt = content.setStartedAt else {
            return .set
        }
        guard let endsAt = content.setTargetEndsAt else {
            return .timedSetRunning(startedAt: startedAt)
        }
        if isStale || endsAt <= startedAt {
            return .timedSetOver(endedAt: endsAt)
        }
        return .timedSet(interval: startedAt...endsAt)
    }
}
