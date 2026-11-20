import Domain
import Synchronization

final class FakeRestNotificationScheduler: RestNotificationScheduler {
    private struct State {
        var scheduled: RestNotificationRequest?
        var cancelCount = 0
        var scheduledSetEnd: SetEndNotificationRequest?
        var cancelSetEndCount = 0
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

    var scheduledSetEnd: SetEndNotificationRequest? {
        return state.withLock { state in
            return state.scheduledSetEnd
        }
    }

    var cancelSetEndCount: Int {
        return state.withLock { state in
            return state.cancelSetEndCount
        }
    }

    func scheduleSetEnd(_ request: SetEndNotificationRequest) async {
        state.withLock { state in
            state.scheduledSetEnd = request
        }
    }

    func cancelSetEnd() async {
        state.withLock { state in
            state.scheduledSetEnd = nil
            state.cancelSetEndCount += 1
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
