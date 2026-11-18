import Foundation

public struct RestPeriod: Hashable, Sendable {
    public static let adjustmentStepSeconds = 15

    public let startedAt: Date
    public let endsAt: Date

    public init(startedAt: Date, endsAt: Date) {
        self.startedAt = startedAt
        self.endsAt = endsAt
    }

    public init(startedAt: Date, seconds: Int) {
        self.init(startedAt: startedAt, endsAt: startedAt.addingTimeInterval(TimeInterval(seconds)))
    }

    public var duration: TimeInterval {
        return endsAt.timeIntervalSince(startedAt)
    }

    public func isActive(at date: Date) -> Bool {
        return date < endsAt
    }

    public func remaining(at date: Date) -> TimeInterval {
        return max(endsAt.timeIntervalSince(date), .zero)
    }

    public func adjusted(bySeconds seconds: Int, now: Date) -> RestPeriod? {
        let newEnd = endsAt.addingTimeInterval(TimeInterval(seconds))
        guard newEnd > now else {
            return nil
        }
        return RestPeriod(startedAt: startedAt, endsAt: newEnd)
    }
}
