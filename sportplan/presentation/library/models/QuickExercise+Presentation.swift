import Domain
import Foundation

extension QuickExercise {
    var title: String {
        switch self {
        case .benchPress:
            return String(localized: "quickExercise.benchPress")
        case .squat:
            return String(localized: "quickExercise.squat")
        case .deadlift:
            return String(localized: "quickExercise.deadlift")
        case .pullUp:
            return String(localized: "quickExercise.pullUp")
        case .dip:
            return String(localized: "quickExercise.dip")
        case .legPress:
            return String(localized: "quickExercise.legPress")
        case .plank:
            return String(localized: "quickExercise.plank")
        }
    }
}
