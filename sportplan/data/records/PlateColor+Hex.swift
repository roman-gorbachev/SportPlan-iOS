import Domain

nonisolated extension PlateColor {
    private static let hexPrefix = "#"
    private static let hexDigitCount = 6
    private static let hexRadix = 16

    init?(hexString: String) {
        guard hexString.hasPrefix(Self.hexPrefix) else {
            return nil
        }
        let digits = hexString.dropFirst(Self.hexPrefix.count)
        guard digits.count == Self.hexDigitCount, let rgb = Int(digits, radix: Self.hexRadix) else {
            return nil
        }
        self.init(rgb: rgb)
    }

    var hexString: String {
        let digits = String(rgb, radix: Self.hexRadix, uppercase: true)
        let padding = String(repeating: "0", count: max(0, Self.hexDigitCount - digits.count))
        return Self.hexPrefix + padding + digits
    }
}
