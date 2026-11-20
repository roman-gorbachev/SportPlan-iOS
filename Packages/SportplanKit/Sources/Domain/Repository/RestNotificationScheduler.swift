public protocol RestNotificationScheduler: Sendable {
    func schedule(_ request: RestNotificationRequest) async
    func cancel() async
    func scheduleSetEnd(_ request: SetEndNotificationRequest) async
    func cancelSetEnd() async
}
