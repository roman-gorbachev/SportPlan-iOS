public struct ObserveGymEquipmentUseCase: Sendable {
    private let repository: any EquipmentRepository

    public init(repository: any EquipmentRepository) {
        self.repository = repository
    }

    public func execute() -> AsyncThrowingStream<[Equipment], any Error> {
        return repository.observeActive()
    }
}
