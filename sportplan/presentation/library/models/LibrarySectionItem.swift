import Domain

struct LibrarySectionItem: Identifiable, Hashable {
    let category: ExerciseCategory
    let title: String
    let exercises: [LibraryExerciseItem]

    var id: ExerciseCategory {
        return category
    }
}
