public struct WorkoutActivityPlate: Codable, Hashable, Sendable {
    public let rgb: Int
    public let kilograms: Double

    public init(rgb: Int, kilograms: Double) {
        self.rgb = rgb
        self.kilograms = kilograms
    }
}
