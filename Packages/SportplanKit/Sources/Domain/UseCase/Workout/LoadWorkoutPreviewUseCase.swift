import Foundation

public struct LoadWorkoutPreviewUseCase: Sendable {
    private static let longBreakDays = 10

    private let workoutRepository: any WorkoutRepository
    private let programRepository: any ProgramRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(
        workoutRepository: any WorkoutRepository,
        programRepository: any ProgramRepository,
        now: @escaping @Sendable () -> Date,
        calendar: Calendar = .current
    ) {
        self.workoutRepository = workoutRepository
        self.programRepository = programRepository
        self.now = now
        self.calendar = calendar
    }

    public func execute(dayId: UUID) async throws -> WorkoutPreview {
        guard let detail = try await programRepository.day(id: dayId) else {
            throw WorkoutError.notFound
        }
        var exercises: [WorkoutPreviewExercise] = []
        for item in detail.exercises {
            let planned = item.plannedExercise
            let previousSets = try await workoutRepository.previousSets(exerciseId: item.exercise.id)
            let previousWorkoutExercise = try await workoutRepository.previousWorkoutExercise(exerciseId: item.exercise.id)
            let plannedSets = WorkoutSetPlanner.plannedSets(
                for: item.exercise,
                workoutExerciseId: UUID(),
                targetSets: planned.targetSets,
                targetReps: planned.targetReps,
                startWeight: planned.startWeight,
                targetDurationSeconds: planned.targetDurationSeconds,
                previousSets: previousSets
            )
            let progressionWeight = ProgressionSuggestion.weight(
                exercise: item.exercise,
                previousWorkoutExercise: previousWorkoutExercise,
                previousWorkingSets: previousSets.filter { entry in
                    return !entry.isWarmup
                }
            ).flatMap { suggested in
                let hasLighterSet = plannedSets.contains { entry in
                    return entry.weight < suggested
                }
                return hasLighterSet ? suggested : nil
            }
            exercises.append(WorkoutPreviewExercise(
                item: item,
                plannedSets: plannedSets,
                hasHistory: !previousSets.isEmpty,
                progressionWeight: progressionWeight
            ))
        }
        let lastWorkoutAt = try await workoutRepository.lastWorkoutDate(programDayId: dayId)
        return WorkoutPreview(
            detail: detail,
            lastWorkoutAt: lastWorkoutAt,
            exercises: exercises,
            tip: tip(exercises: exercises, lastWorkoutAt: lastWorkoutAt)
        )
    }

    private func tip(exercises: [WorkoutPreviewExercise], lastWorkoutAt: Date?) -> WorkoutPreviewTip? {
        if let progressing = exercises.first(where: { exercise in return exercise.progressionWeight != nil }),
           let weight = progressing.progressionWeight {
            return .progression(exerciseName: progressing.item.exercise.exercise.name, weight: weight)
        }
        let hasHistory = exercises.contains { exercise in
            return exercise.hasHistory
        }
        if !exercises.isEmpty && !hasHistory {
            return .firstWorkout
        }
        guard let lastWorkoutAt else {
            return nil
        }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastWorkoutAt),
            to: calendar.startOfDay(for: now())
        ).day ?? .zero
        return days >= Self.longBreakDays ? .longBreak(days: days) : nil
    }
}
