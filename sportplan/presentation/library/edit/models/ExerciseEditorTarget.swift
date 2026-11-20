import Foundation

struct ExerciseEditorTarget: Identifiable, Hashable {
    let exerciseId: UUID

    var id: UUID {
        return exerciseId
    }
}
