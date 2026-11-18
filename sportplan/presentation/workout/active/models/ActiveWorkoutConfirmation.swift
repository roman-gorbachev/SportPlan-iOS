enum ActiveWorkoutConfirmation {
    case finish(incompleteSetCount: Int)
    case discardEmpty
    case cancel
}
