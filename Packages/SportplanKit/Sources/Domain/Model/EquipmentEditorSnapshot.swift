public struct EquipmentEditorSnapshot: Hashable, Sendable {
    public let equipment: Equipment
    public let exerciseCount: Int

    public init(equipment: Equipment, exerciseCount: Int) {
        self.equipment = equipment
        self.exerciseCount = exerciseCount
    }

    public var isKindLocked: Bool {
        return exerciseCount > 0
    }
}
