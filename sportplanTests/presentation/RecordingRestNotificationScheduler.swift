import Domain
import Synchronization

final class RecordingRestNotificationScheduler: RestNotificationScheduler {
    private let lastRequest = Mutex<RestNotificationRequest?>(nil)
    private let lastSetEndRequest = Mutex<SetEndNotificationRequest?>(nil)

    var scheduled: RestNotificationRequest? {
        return lastRequest.withLock { request in
            return request
        }
    }

    var scheduledSetEnd: SetEndNotificationRequest? {
        return lastSetEndRequest.withLock { request in
            return request
        }
    }

    func schedule(_ request: RestNotificationRequest) async {
        lastRequest.withLock { stored in
            stored = request
        }
    }

    func cancel() async {
        lastRequest.withLock { stored in
            stored = nil
        }
    }

    func scheduleSetEnd(_ request: SetEndNotificationRequest) async {
        lastSetEndRequest.withLock { stored in
            stored = request
        }
    }

    func cancelSetEnd() async {
        lastSetEndRequest.withLock { stored in
            stored = nil
        }
    }
}
