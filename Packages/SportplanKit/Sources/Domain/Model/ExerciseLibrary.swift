import Foundation

public struct ExerciseLibrary: Hashable, Sendable {
    public let sections: [ExerciseLibrarySection]

    public init(exercises: [LibraryExercise]) {
        let grouped = Dictionary(grouping: exercises) { item in
            return ExerciseCategory(loadKind: item.loadKind)
        }
        sections = ExerciseCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else {
                return nil
            }
            let sorted = items.sorted { lhs, rhs in
                return lhs.exercise.name.localizedStandardCompare(rhs.exercise.name) == .orderedAscending
            }
            return ExerciseLibrarySection(category: category, exercises: sorted)
        }
    }

    public var count: Int {
        return sections.reduce(0) { total, section in
            return total + section.exercises.count
        }
    }

    public var isEmpty: Bool {
        return sections.isEmpty
    }

    public func filtered(by query: String) -> ExerciseLibrary {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return self
        }
        let matching = sections.flatMap { section in
            return section.exercises
        }.filter { item in
            return item.exercise.name.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
        return ExerciseLibrary(exercises: matching)
    }
}
