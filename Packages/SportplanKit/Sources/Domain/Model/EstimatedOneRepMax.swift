public enum EstimatedOneRepMax {
    public static let maximumReps = 12

    private static let singleRep = 1
    private static let epleyDivisor = 30.0

    public static func make(weight: Weight, reps: Int?) -> Weight? {
        guard let reps, reps >= singleRep, reps <= maximumReps else {
            return nil
        }
        guard reps > singleRep else {
            return weight
        }
        let grams = Double(weight.grams) * (1 + Double(reps) / epleyDivisor)
        return Weight(grams: Int(grams.rounded()))
    }
}
