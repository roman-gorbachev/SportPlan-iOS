import Foundation

public struct EquipmentDraft: Hashable, Sendable {
    private static let maximumBaseWeight = Weight(grams: 500_000)
    private static let minimumWeightStep = Weight(grams: 250)
    private static let maximumWeightStep = Weight(grams: 50_000)

    public var name: String
    public var kind: EquipmentKind
    public var baseWeight: Weight
    public var weightStep: Weight

    public init(name: String, kind: EquipmentKind, baseWeight: Weight, weightStep: Weight) {
        self.name = name
        self.kind = kind
        self.baseWeight = baseWeight
        self.weightStep = weightStep
    }

    public init(_ equipment: Equipment) {
        self.init(
            name: equipment.name,
            kind: equipment.kind,
            baseWeight: equipment.baseWeight,
            weightStep: equipment.weightStep
        )
    }

    public var trimmedName: String {
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var effectiveBaseWeight: Weight {
        return kind.hasBaseWeight ? baseWeight : .zero
    }

    public var validationIssues: Set<EquipmentValidationIssue> {
        var issues = Set<EquipmentValidationIssue>()
        if trimmedName.isEmpty {
            issues.insert(.emptyName)
        }
        if kind.hasBaseWeight, baseWeight < .zero || baseWeight > Self.maximumBaseWeight {
            issues.insert(.baseWeightOutOfRange)
        }
        if weightStep < Self.minimumWeightStep || weightStep > Self.maximumWeightStep {
            issues.insert(.weightStepOutOfRange)
        }
        return issues
    }

    public var isValid: Bool {
        return validationIssues.isEmpty
    }
}
