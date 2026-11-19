import Domain
import Foundation

extension PlatePaletteColor {
    var title: String {
        switch self {
        case .red:
            return String(localized: "plate.color.red")
        case .blue:
            return String(localized: "plate.color.blue")
        case .yellow:
            return String(localized: "plate.color.yellow")
        case .green:
            return String(localized: "plate.color.green")
        case .white:
            return String(localized: "plate.color.white")
        case .black:
            return String(localized: "plate.color.black")
        case .steel:
            return String(localized: "plate.color.steel")
        }
    }
}
