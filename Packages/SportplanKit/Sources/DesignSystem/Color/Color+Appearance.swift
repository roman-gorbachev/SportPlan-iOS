import SwiftUI

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

extension Color {
    nonisolated private static let channelShiftRed = 16
    nonisolated private static let channelShiftGreen = 8
    nonisolated private static let channelMask = 0xFF
    nonisolated private static let channelMaximum = 255.0

    nonisolated init(light: Int, dark: Int) {
        #if canImport(UIKit)
        let dynamic = UIColor { @Sendable traits in
            return traits.userInterfaceStyle == .dark ? Self.platformColor(hex: dark) : Self.platformColor(hex: light)
        }
        self.init(uiColor: dynamic)
        #else
        let dynamic = NSColor(name: nil) { @Sendable appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? Self.platformColor(hex: dark) : Self.platformColor(hex: light)
        }
        self.init(nsColor: dynamic)
        #endif
    }

    nonisolated init(hex: Int) {
        self.init(light: hex, dark: hex)
    }

    #if canImport(UIKit)
    nonisolated private static func platformColor(hex: Int) -> UIColor {
        return UIColor(red: red(hex), green: green(hex), blue: blue(hex), alpha: 1)
    }
    #else
    nonisolated private static func platformColor(hex: Int) -> NSColor {
        return NSColor(srgbRed: red(hex), green: green(hex), blue: blue(hex), alpha: 1)
    }
    #endif

    nonisolated private static func red(_ hex: Int) -> CGFloat {
        return CGFloat((hex >> channelShiftRed) & channelMask) / channelMaximum
    }

    nonisolated private static func green(_ hex: Int) -> CGFloat {
        return CGFloat((hex >> channelShiftGreen) & channelMask) / channelMaximum
    }

    nonisolated private static func blue(_ hex: Int) -> CGFloat {
        return CGFloat(hex & channelMask) / channelMaximum
    }
}
