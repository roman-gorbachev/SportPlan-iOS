public struct PlateDraft: Hashable, Sendable {
    public var weight: Weight
    public var color: PlateColor

    public init(weight: Weight, color: PlateColor) {
        self.weight = weight
        self.color = color
    }

    public func validationIssues(takenWeights: Set<Weight>) -> Set<PlateValidationIssue> {
        var issues = Set<PlateValidationIssue>()
        if weight < Plate.minimumWeight || weight > Plate.maximumWeight {
            issues.insert(.weightOutOfRange)
        }
        if takenWeights.contains(weight) {
            issues.insert(.duplicateWeight)
        }
        return issues
    }
}
