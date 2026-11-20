import Domain
import Foundation
import UserNotifications

nonisolated final class RestNotificationCenter: NSObject, RestNotificationScheduler, UNUserNotificationCenterDelegate {
    private static let identifier = "rest.finished"
    private static let setEndIdentifier = "set.finished"
    private static let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]
    private static let minimumInterval: TimeInterval = 1
    private static let alertSoundName = UNNotificationSoundName(AlertSoundPlayer.soundFileName)

    private let soundPlayer: AlertSoundPlayer

    init(soundPlayer: AlertSoundPlayer) {
        self.soundPlayer = soundPlayer
    }

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func schedule(_ request: RestNotificationRequest) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        let interval = request.endsAt.timeIntervalSinceNow
        guard interval >= Self.minimumInterval, await isAuthorized(center) else {
            return
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let notification = UNNotificationRequest(identifier: Self.identifier, content: content(for: request), trigger: trigger)
        try? await center.add(notification)
    }

    func cancel() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
    }

    func scheduleSetEnd(_ request: SetEndNotificationRequest) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.setEndIdentifier])
        let interval = request.endsAt.timeIntervalSinceNow
        guard interval >= Self.minimumInterval, await isAuthorized(center) else {
            return
        }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let notification = UNNotificationRequest(
            identifier: Self.setEndIdentifier,
            content: setEndContent(for: request),
            trigger: trigger
        )
        try? await center.add(notification)
    }

    func cancelSetEnd() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.setEndIdentifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.setEndIdentifier])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard soundPlayer.playThroughHeadphones() else {
            return [.sound]
        }
        return []
    }

    private func content(for request: RestNotificationRequest) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "rest.notification.title")
        if let exerciseName = request.exerciseName, let setNumber = request.setNumber {
            content.body = String(localized: "rest.notification.next \(exerciseName) \(setNumber)")
        } else {
            content.body = String(localized: "rest.notification.finish")
        }
        content.sound = UNNotificationSound(named: Self.alertSoundName)
        return content
    }

    private func setEndContent(for request: SetEndNotificationRequest) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "set.notification.title")
        if let setNumber = request.setNumber {
            content.body = String(localized: "set.notification.body \(request.exerciseName) \(setNumber)")
        } else {
            content.body = String(localized: "set.notification.bodyWithoutNumber \(request.exerciseName)")
        }
        content.sound = UNNotificationSound(named: Self.alertSoundName)
        return content
    }

    private func isAuthorized(_ center: UNUserNotificationCenter) async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: Self.authorizationOptions)) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}
