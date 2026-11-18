import Domain

struct PickerSectionItem: Identifiable {
    let category: ExerciseCategory
    let title: String
    let exercises: [PickerExerciseItem]

    var id: ExerciseCategory {
        return category
    }
}
