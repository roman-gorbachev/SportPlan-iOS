import Foundation

enum AppLocale {
    static let current = Locale(identifier: Bundle.main.preferredLocalizations.first ?? Locale.current.identifier)
}
