import Domain
import Foundation

extension ExerciseLoadKind {
    var title: String {
        switch self {
        case .equipment(.barbell):
            return String(localized: "addExercise.kind.barbell")
        case .equipment(.dumbbell):
            return String(localized: "addExercise.kind.dumbbell")
        case .equipment(.plateLoadedMachine):
            return String(localized: "addExercise.kind.plateLoadedMachine")
        case .equipment(.selectorizedMachine):
            return String(localized: "addExercise.kind.selectorizedMachine")
        case .bodyweight:
            return String(localized: "addExercise.kind.bodyweight")
        }
    }

    var examples: String {
        switch self {
        case .equipment(.barbell):
            return String(localized: "addExercise.kind.barbell.examples")
        case .equipment(.dumbbell):
            return String(localized: "addExercise.kind.dumbbell.examples")
        case .equipment(.plateLoadedMachine):
            return String(localized: "addExercise.kind.plateLoadedMachine.examples")
        case .equipment(.selectorizedMachine):
            return String(localized: "addExercise.kind.selectorizedMachine.examples")
        case .bodyweight:
            return String(localized: "addExercise.kind.bodyweight.examples")
        }
    }

    var newEquipmentTitle: String? {
        switch self {
        case .equipment(.barbell):
            return String(localized: "addExercise.equipment.new.barbell")
        case .equipment(.dumbbell):
            return String(localized: "addExercise.equipment.new.dumbbell")
        case .equipment(.plateLoadedMachine), .equipment(.selectorizedMachine):
            return String(localized: "addExercise.equipment.new.machine")
        case .bodyweight:
            return nil
        }
    }

    var editorEquipmentHeader: String? {
        switch self {
        case .equipment(.barbell):
            return String(localized: "exerciseEditor.equipment.header.barbell")
        case .equipment(.dumbbell):
            return String(localized: "exerciseEditor.equipment.header.dumbbell")
        case .equipment(.plateLoadedMachine):
            return String(localized: "exerciseEditor.equipment.header.plateLoadedMachine")
        case .equipment(.selectorizedMachine):
            return String(localized: "exerciseEditor.equipment.header.selectorizedMachine")
        case .bodyweight:
            return nil
        }
    }

    var editorEquipmentLockHint: String? {
        switch self {
        case .equipment(.barbell):
            return String(localized: "exerciseEditor.equipment.locked.barbell")
        case .equipment(.dumbbell):
            return String(localized: "exerciseEditor.equipment.locked.dumbbell")
        case .equipment(.plateLoadedMachine):
            return String(localized: "exerciseEditor.equipment.locked.plateLoadedMachine")
        case .equipment(.selectorizedMachine):
            return String(localized: "exerciseEditor.equipment.locked.selectorizedMachine")
        case .bodyweight:
            return nil
        }
    }
}
