import Domain
import Foundation
import Observation

@Observable
final class LibraryViewModel {
    @ObservationIgnored private let observeExerciseLibrary: ObserveExerciseLibraryUseCase
    @ObservationIgnored private let countProgramDaysUsingExercise: CountProgramDaysUsingExerciseUseCase
    @ObservationIgnored private let archiveExercise: ArchiveExerciseUseCase
    @ObservationIgnored private let observeArchivedExercises: ObserveArchivedExercisesUseCase
    @ObservationIgnored private var archivedCount = 0
    @ObservationIgnored private var library: ExerciseLibrary?
    @ObservationIgnored private var searchQuery = ""
    @ObservationIgnored private var pendingArchive: LibraryArchiveConfirmation?
    @ObservationIgnored private var isShowingArchiveError = false

    private(set) var libraryUiState: LibraryUiState = .loading

    init(
        observeExerciseLibrary: ObserveExerciseLibraryUseCase,
        countProgramDaysUsingExercise: CountProgramDaysUsingExerciseUseCase,
        archiveExercise: ArchiveExerciseUseCase,
        observeArchivedExercises: ObserveArchivedExercisesUseCase
    ) {
        self.observeExerciseLibrary = observeExerciseLibrary
        self.countProgramDaysUsingExercise = countProgramDaysUsingExercise
        self.archiveExercise = archiveExercise
        self.observeArchivedExercises = observeArchivedExercises
    }

    func observe() async {
        do {
            for try await library in observeExerciseLibrary.execute() {
                self.library = library
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            libraryUiState = .error(error: error)
        }
    }

    func observeArchive() async {
        do {
            for try await archived in observeArchivedExercises.execute() {
                archivedCount = archived.count
                publish()
            }
        } catch {
            guard !Task.isCancelled else {
                return
            }
            archivedCount = 0
            publish()
        }
    }

    func updateSearchQuery(_ query: String) {
        searchQuery = query
        publish()
    }

    func requestArchive(id: UUID) async {
        guard let item = library?.sections.flatMap(\.exercises).first(where: { item in
            return item.id == id
        }) else {
            return
        }
        do {
            let count = try await countProgramDaysUsingExercise.execute(id: id)
            pendingArchive = LibraryArchiveConfirmation(exerciseId: id, exerciseName: item.exercise.name, programDayCount: count)
        } catch {
            isShowingArchiveError = true
        }
        publish()
    }

    func confirmArchive(id: UUID) async {
        pendingArchive = nil
        publish()
        do {
            try await archiveExercise.execute(id: id)
        } catch {
            isShowingArchiveError = true
            publish()
        }
    }

    func cancelArchive() {
        pendingArchive = nil
        publish()
    }

    func dismissArchiveError() {
        isShowingArchiveError = false
        publish()
    }

    private func publish() {
        guard let library else {
            return
        }
        let visible = library.filtered(by: searchQuery)
        libraryUiState = .success(data: LibraryUiData(
            sections: visible.sections.map(Self.makeSection),
            isLibraryEmpty: library.isEmpty,
            searchQuery: searchQuery,
            archivedCount: archivedCount,
            pendingArchive: pendingArchive,
            isShowingArchiveError: isShowingArchiveError
        ))
    }

    private static func makeSection(_ section: ExerciseLibrarySection) -> LibrarySectionItem {
        return LibrarySectionItem(
            category: section.category,
            title: section.category.libraryTitle,
            exercises: section.exercises.map(makeItem)
        )
    }

    private static func makeItem(_ item: LibraryExercise) -> LibraryExerciseItem {
        let metric = item.exercise.metric.listTitle
        let detail = item.equipment.map { equipment in
            return String(localized: "library.row.detail \(equipment.name) \(metric)")
        } ?? metric
        return LibraryExerciseItem(id: item.id, name: item.exercise.name, detail: detail)
    }
}
