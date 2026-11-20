struct ExerciseLoadKindResolver: Sendable {
    private let equipmentRepository: any EquipmentRepository

    init(equipmentRepository: any EquipmentRepository) {
        self.equipmentRepository = equipmentRepository
    }

    func loadKind(of exercise: Exercise) async throws -> ExerciseLoadKind {
        switch exercise.load {
        case .bodyweight:
            return .bodyweight
        case let .equipment(id):
            guard let equipment = try await equipmentRepository.equipment(id: id) else {
                throw ExerciseError.notFound
            }
            return .equipment(equipment.kind)
        }
    }
}
