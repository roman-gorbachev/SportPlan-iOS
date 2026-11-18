import Foundation
import Synchronization

final class TestClock: Sendable {
    private let current: Mutex<Date>

    init(_ date: Date = DomainFixtures.referenceDate) {
        current = Mutex(date)
    }

    var now: @Sendable () -> Date {
        return { [self] in
            return current.withLock { date in
                return date
            }
        }
    }

    func advance(by interval: TimeInterval) {
        current.withLock { date in
            date = date.addingTimeInterval(interval)
        }
    }
}
