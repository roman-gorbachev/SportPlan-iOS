public struct ResetPlatesToStandardUseCase: Sendable {
    private let repository: any PlateRepository

    public init(repository: any PlateRepository) {
        self.repository = repository
    }

    public func execute() async throws {
        try await repository.replaceAll(with: StandardPlates.makeIWFSet())
    }
}
