import Domain
import Foundation

enum WeightFormatting {
    private static let maximumFractionDigits = 2
    private static let decimalComma = ","
    private static let decimalPoint = "."
    private static let appLocale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)

    static func kilograms(_ weight: Weight) -> String {
        return weight.kilograms.formatted(.number.grouping(.never).precision(.fractionLength(0...maximumFractionDigits)).locale(appLocale))
    }

    static func parseKilograms(_ text: String) -> Weight? {
        let normalized = text
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: decimalComma, with: decimalPoint)
        guard let value = Double(normalized), value.isFinite else {
            return nil
        }
        return Weight(kilograms: value)
    }
}
