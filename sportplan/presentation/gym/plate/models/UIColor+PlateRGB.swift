import UIKit

extension UIColor {
    private static let channelShiftRed = 16
    private static let channelShiftGreen = 8
    private static let channelMask = 0xFF
    private static let channelMaximum: CGFloat = 255

    convenience init(plateRGB rgb: Int) {
        self.init(
            red: CGFloat((rgb >> Self.channelShiftRed) & Self.channelMask) / Self.channelMaximum,
            green: CGFloat((rgb >> Self.channelShiftGreen) & Self.channelMask) / Self.channelMaximum,
            blue: CGFloat(rgb & Self.channelMask) / Self.channelMaximum,
            alpha: 1
        )
    }

    var plateRGB: Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Self.channel(red) << Self.channelShiftRed) | (Self.channel(green) << Self.channelShiftGreen) | Self.channel(blue)
    }

    private static func channel(_ value: CGFloat) -> Int {
        let clamped = min(max(value, 0), 1)
        return Int((clamped * channelMaximum).rounded())
    }
}
