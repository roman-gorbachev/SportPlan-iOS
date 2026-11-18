import Domain

enum AddExerciseTarget: Hashable, Identifiable {
    case blank
    case quick(QuickExercise)

    var id: Self {
        return self
    }
}
