import Foundation
import Synchronization
import WorkoutActivity

final class RecordingWorkoutActivityController: WorkoutActivityController {
    struct Shown: Sendable {
        let attributes: WorkoutActivityAttributes
        let content: WorkoutActivityContent
        let staleDate: Date?
    }

    private let shownItems = Mutex<[Shown]>([])
    private let endCalls = Mutex(0)

    var shown: [Shown] {
        return shownItems.withLock { items in
            return items
        }
    }

    var endCount: Int {
        return endCalls.withLock { count in
            return count
        }
    }

    func show(attributes: WorkoutActivityAttributes, content: WorkoutActivityContent, staleDate: Date?) async {
        shownItems.withLock { items in
            items.append(Shown(attributes: attributes, content: content, staleDate: staleDate))
        }
    }

    func end() async {
        endCalls.withLock { count in
            count += 1
        }
    }
}
