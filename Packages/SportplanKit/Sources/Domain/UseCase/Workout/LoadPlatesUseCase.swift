public struct LoadPlatesUseCase: Sendable {
    private let repository: any PlateRepository

    public init(repository: any PlateRepository) {
        self.repository = repository
    }

    public func execute() async throws -> [Plate] {
        return try await repository.plates()
    }
}
