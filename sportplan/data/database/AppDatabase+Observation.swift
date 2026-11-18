import GRDB

nonisolated extension AppDatabase {
    func stream<Value: Sendable>(
        of observation: ValueObservation<ValueReducers.Fetch<Value>>
    ) -> AsyncThrowingStream<Value, any Error> {
        let reader = self.reader
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in observation.values(in: reader) {
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
