import Foundation

public enum WorkoutRecords {
    public static func recordSetIds(in workouts: [FinishedWorkout]) -> Set<UUID> {
        let itemsByExercise = Dictionary(grouping: workouts.flatMap(\.exercises)) { item in
            return item.exercise.id
        }
        var recordIds = Set<UUID>()
        for items in itemsByExercise.values {
            guard let profile = items.first?.exercise.recordProfile else {
                continue
            }
            recordIds.formUnion(RecordBaseline.empty.recordSetIds(in: items.flatMap(\.sets), profile: profile))
        }
        return recordIds
    }
}
