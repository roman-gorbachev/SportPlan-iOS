import Domain
import Synchronization

final class RecordingRestNotificationScheduler: RestNotificationScheduler {
    private let lastRequest = Mutex<RestNotificationRequest?>(nil)

    var scheduled: RestNotificationRequest? {
        return lastRequest.withLock { request in
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
}
