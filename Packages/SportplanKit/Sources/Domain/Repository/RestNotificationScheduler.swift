public protocol RestNotificationScheduler: Sendable {
    func schedule(_ request: RestNotificationRequest) async
    func cancel() async
}
