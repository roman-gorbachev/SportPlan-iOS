import Domain
import Synchronization

final class FakeRestNotificationScheduler: RestNotificationScheduler {
    private struct State {
        var scheduled: RestNotificationRequest?
        var cancelCount = 0
    }

    private let state = Mutex(State())

    var scheduled: RestNotificationRequest? {
        return state.withLock { state in
            return state.scheduled
        }
    }

    var cancelCount: Int {
        return state.withLock { state in
            return state.cancelCount
        }
    }

    func schedule(_ request: RestNotificationRequest) async {
        state.withLock { state in
            state.scheduled = request
        }
    }

    func cancel() async {
        state.withLock { state in
            state.scheduled = nil
            state.cancelCount += 1
        }
    }
}
