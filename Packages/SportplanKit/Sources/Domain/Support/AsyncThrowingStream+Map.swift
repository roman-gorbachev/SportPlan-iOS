extension AsyncThrowingStream where Element: Sendable, Failure == any Error {
    func mapElements<Mapped: Sendable>(
        _ transform: @escaping @Sendable (Element) -> Mapped
    ) -> AsyncThrowingStream<Mapped, any Error> {
        let source = self
        return AsyncThrowingStream<Mapped, any Error> { continuation in
            let task = Task {
                do {
                    for try await element in source {
                        continuation.yield(transform(element))
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
