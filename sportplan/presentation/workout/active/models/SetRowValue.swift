import Foundation

enum SetRowValue {
    case weightReps(weight: String, reps: String)
    case bodyweightReps(addedWeight: String?, reps: String)
    case duration(text: String, runningSince: Date?, targetEndsAt: Date?)
}
