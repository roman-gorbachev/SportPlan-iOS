import Foundation

enum RestFormatting {
    static func clock(seconds: Int) -> String {
        return Duration.seconds(seconds).formatted(.time(pattern: .minuteSecond).locale(AppLocale.current))
    }

    static func spoken(seconds: Int) -> String {
        return Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .wide).locale(AppLocale.current))
    }
}
