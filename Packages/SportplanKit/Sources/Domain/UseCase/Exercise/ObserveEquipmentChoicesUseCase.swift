public struct ObserveEquipmentChoicesUseCase: Sendable {
    private let repository: any EquipmentRepository

    public init(repository: any EquipmentRepository) {
        self.repository = repository
    }

    public func execute(kind: EquipmentKind) -> AsyncThrowingStream<[Equipment], any Error> {
        return repository.observeActive().mapElements { equipment in
            return equipment.filter { item in
                return item.kind == kind
            }
        }
    }
}
