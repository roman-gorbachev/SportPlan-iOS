import Foundation

public struct LoadPlateEditorUseCase: Sendable {
    private let repository: any PlateRepository

    public init(repository: any PlateRepository) {
        self.repository = repository
    }

    public func execute(id: UUID?) async throws -> PlateEditorSnapshot {
        let plates = try await repository.plates()
        var plate: Plate?
        if let id {
            guard let existing = plates.first(where: { candidate in
                return candidate.id == id
            }) else {
                throw PlateError.notFound
            }
            plate = existing
        }
        let takenWeights = Set(plates.filter { candidate in
            return candidate.id != id
        }.map(\.weight))
        return PlateEditorSnapshot(plate: plate, takenWeights: takenWeights)
    }
}
