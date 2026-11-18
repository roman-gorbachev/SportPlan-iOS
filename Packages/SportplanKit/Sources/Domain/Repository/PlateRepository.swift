public protocol PlateRepository: Sendable {
    func plates() async throws -> [Plate]
}
