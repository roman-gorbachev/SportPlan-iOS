public enum HeatmapLevel: Int, CaseIterable, Hashable, Sendable {
    case rest
    case light
    case moderate
    case high
    case peak

    private static let lightUpperBound = 6
    private static let moderateUpperBound = 12
    private static let highUpperBound = 18

    public init(workingSetCount: Int) {
        switch workingSetCount {
        case ...Int.zero:
            self = .rest
        case ...Self.lightUpperBound:
            self = .light
        case ...Self.moderateUpperBound:
            self = .moderate
        case ...Self.highUpperBound:
            self = .high
        default:
            self = .peak
        }
    }
}
