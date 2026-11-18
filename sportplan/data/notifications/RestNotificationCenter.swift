import Domain
import Foundation
import UserNotifications

nonisolated final class RestNotificationCenter: NSObject, RestNotificationScheduler, UNUserNotificationCenterDelegate {
    private static let identifier = "rest.finished"
    private static let authorizationOptions: UNAuthorizationOptions = [.alert, .sound]
    private static let minimumInterval: TimeInterval = 1

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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.sound]
    }

    private func content(for request: RestNotificationRequest) -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "rest.notification.title")
        if let exerciseName = request.exerciseName, let setNumber = request.setNumber {
            content.body = String(localized: "rest.notification.next \(exerciseName) \(setNumber)")
        } else {
            content.body = String(localized: "rest.notification.finish")
        }
        content.sound = .default
        content.interruptionLevel = .timeSensitive
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
