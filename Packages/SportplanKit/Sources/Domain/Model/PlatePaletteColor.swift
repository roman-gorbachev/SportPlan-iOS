public enum PlatePaletteColor: CaseIterable, Hashable, Sendable {
    case red
    case blue
    case yellow
    case green
    case white
    case black
    case steel

    private static let redRGB = 0xD7261E
    private static let blueRGB = 0x1F5FBF
    private static let yellowRGB = 0xF2C200
    private static let greenRGB = 0x1E8A4C
    private static let whiteRGB = 0xFFFFFF
    private static let blackRGB = 0x2A2A2A
    private static let steelRGB = 0xA8A8A3

    public init?(color: PlateColor) {
        guard let match = Self.allCases.first(where: { candidate in
            return candidate.color == color
        }) else {
            return nil
        }
        self = match
    }

    public var color: PlateColor {
        switch self {
        case .red:
            return PlateColor(rgb: Self.redRGB)
        case .blue:
            return PlateColor(rgb: Self.blueRGB)
        case .yellow:
            return PlateColor(rgb: Self.yellowRGB)
        case .green:
            return PlateColor(rgb: Self.greenRGB)
        case .white:
            return PlateColor(rgb: Self.whiteRGB)
        case .black:
            return PlateColor(rgb: Self.blackRGB)
        case .steel:
            return PlateColor(rgb: Self.steelRGB)
        }
    }
}
