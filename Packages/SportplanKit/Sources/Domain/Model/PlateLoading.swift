public struct PlateLoading: Hashable, Sendable {
    private static let sideCount = 2

    public let platesPerSide: [Plate]
    public let remainderPerSide: Weight

    public init(platesPerSide: [Plate], remainderPerSide: Weight) {
        self.platesPerSide = platesPerSide
        self.remainderPerSide = remainderPerSide
    }

    public init(weight: Weight, baseWeight: Weight, plates: [Plate]) {
        guard weight > baseWeight else {
            self.init(platesPerSide: [], remainderPerSide: .zero)
            return
        }
        let target = Weight(grams: (weight - baseWeight).grams / Self.sideCount)
        let available = plates
            .filter { plate in
                return plate.weight > .zero
            }
            .sorted { lhs, rhs in
                return lhs.weight > rhs.weight
            }
        var remaining = target
        var loaded: [Plate] = []
        for plate in available {
            while remaining >= plate.weight {
                loaded.append(plate)
                remaining = remaining - plate.weight
            }
        }
        self.init(platesPerSide: loaded, remainderPerSide: remaining)
    }

    public init?(weight: Weight, exercise: LibraryExercise, plates: [Plate]) {
        guard exercise.usesPlates else {
            return nil
        }
        self.init(weight: weight, baseWeight: exercise.minimumWeight, plates: plates)
    }

    public var isExact: Bool {
        return remainderPerSide == .zero
    }
}
