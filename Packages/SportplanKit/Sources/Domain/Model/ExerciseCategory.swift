public enum ExerciseCategory: Hashable, Sendable, CaseIterable {
    case freeWeight
    case machine
    case bodyweight

    public init(loadKind: ExerciseLoadKind) {
        switch loadKind {
        case .equipment(.barbell), .equipment(.dumbbell):
            self = .freeWeight
        case .equipment(.plateLoadedMachine), .equipment(.selectorizedMachine):
            self = .machine
        case .bodyweight:
            self = .bodyweight
        }
    }

    public var loadKinds: [ExerciseLoadKind] {
        return ExerciseLoadKind.allCases.filter { loadKind in
            return ExerciseCategory(loadKind: loadKind) == self
        }
    }
}
