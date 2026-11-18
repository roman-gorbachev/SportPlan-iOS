import Domain
import Foundation
import Observation

@Observable
final class ActiveWorkoutViewModel {
    private static let noteSaveDelay = Duration.milliseconds(600)

    @ObservationIgnored private let store: ActiveWorkoutStore
    @ObservationIgnored private let loadPlates: LoadPlatesUseCase
    @ObservationIgnored private let addSet: AddSetUseCase
    @ObservationIgnored private let updateSet: UpdateSetUseCase
    @ObservationIgnored private let completeSet: CompleteSetUseCase
    @ObservationIgnored private let startTimedSet: StartTimedSetUseCase
    @ObservationIgnored private let stopTimedSet: StopTimedSetUseCase
    @ObservationIgnored private let removeSet: RemoveSetUseCase
    @ObservationIgnored private let updateWorkoutNote: UpdateWorkoutNoteUseCase
    @ObservationIgnored private let finishWorkout: FinishWorkoutUseCase
    @ObservationIgnored private let cancelWorkout: CancelWorkoutUseCase
    @ObservationIgnored private let adjustRest: AdjustRestUseCase
    @ObservationIgnored private let skipRest: SkipRestUseCase
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var workout: ActiveWorkout?
    @ObservationIgnored private var rest: RestPeriod?
    @ObservationIgnored private var plates: [Plate] = []
    @ObservationIgnored private var editingSetId: UUID?
    @ObservationIgnored private var editorDraft: SetEntryDraft?
    @ObservationIgnored private var noteDraft: String?
    @ObservationIgnored private var noteSaveTask: Task<Void, Never>?
    @ObservationIgnored private var confirmation: ActiveWorkoutConfirmation?
    @ObservationIgnored private var isShowingError = false

    private(set) var activeWorkoutUiState: ActiveWorkoutUiState = .loading

    init(
        store: ActiveWorkoutStore,
        loadPlates: LoadPlatesUseCase,
        addSet: AddSetUseCase,
        updateSet: UpdateSetUseCase,
        completeSet: CompleteSetUseCase,
        startTimedSet: StartTimedSetUseCase,
        stopTimedSet: StopTimedSetUseCase,
        removeSet: RemoveSetUseCase,
        updateWorkoutNote: UpdateWorkoutNoteUseCase,
        finishWorkout: FinishWorkoutUseCase,
        cancelWorkout: CancelWorkoutUseCase,
        adjustRest: AdjustRestUseCase,
        skipRest: SkipRestUseCase
    ) {
        self.store = store
        self.loadPlates = loadPlates
        self.addSet = addSet
        self.updateSet = updateSet
        self.completeSet = completeSet
        self.startTimedSet = startTimedSet
        self.stopTimedSet = stopTimedSet
        self.removeSet = removeSet
        self.updateWorkoutNote = updateWorkoutNote
        self.finishWorkout = finishWorkout
        self.cancelWorkout = cancelWorkout
        self.adjustRest = adjustRest
        self.skipRest = skipRest
    }

    var pickerTarget: ExercisePickerTarget? {
        guard let workout else {
            return nil
        }
        return ExercisePickerTarget(destination: .workout(id: workout.id))
    }

    func observe() async {
        let store = store
        let snapshots = Observations {
            return store.snapshot
        }
        for await snapshot in snapshots {
            apply(snapshot)
        }
    }

    func loadPlateSet() async {
        do {
            plates = try await loadPlates.execute()
        } catch {
            plates = []
        }
        publish()
    }

    func tapSetAction(setId: UUID) async {
        guard case let (item, entry)? = locate(setId: setId) else {
            return
        }
        switch (item.exercise.metric, entry.state) {
        case (_, .completed):
            return
        case (.weightReps, _):
            await perform {
                try await self.completeSet.execute(setId: setId, draft: SetEntryDraft(entry))
            }
        case (.duration, .planned):
            await perform {
                try await self.startTimedSet.execute(setId: setId)
            }
        case (.duration, .running):
            await perform {
                try await self.stopTimedSet.execute(setId: setId)
            }
        }
    }

    func openEditor(setId: UUID) {
        guard case let (item, entry)? = locate(setId: setId), item.exercise.metric == .weightReps else {
            return
        }
        editingSetId = setId
        editorDraft = SetEntryDraft(entry)
        publish()
    }

    func closeEditor() {
        editingSetId = nil
        editorDraft = nil
        publish()
    }

    func incrementEditorWeight() {
        editDraft { draft, item in
            draft.incrementWeight(for: item.exercise)
        }
    }

    func decrementEditorWeight() {
        editDraft { draft, item in
            draft.decrementWeight(for: item.exercise)
        }
    }

    func incrementEditorReps() {
        editDraft { draft, _ in
            draft.incrementReps()
        }
    }

    func decrementEditorReps() {
        editDraft { draft, _ in
            draft.decrementReps()
        }
    }

    func copyLastWorkoutSet() {
        guard let editingSetId, case let (item, entry)? = locate(setId: editingSetId), let previous = item.previousResult(for: entry) else {
            return
        }
        editorDraft = SetEntryDraft(previous)
        publish()
    }

    func saveEditor() async {
        guard let editingSetId, let editorDraft, case let (_, entry)? = locate(setId: editingSetId) else {
            return
        }
        closeEditor()
        await perform {
            if entry.isCompleted {
                try await self.updateSet.execute(setId: editingSetId, draft: editorDraft)
            } else {
                try await self.completeSet.execute(setId: editingSetId, draft: editorDraft)
            }
        }
    }

    func adjustRest(seconds: Int) async {
        await perform {
            try await self.adjustRest.execute(seconds: seconds)
        }
    }

    func skipRest() async {
        await perform {
            try await self.skipRest.execute()
        }
    }

    func addSet(workoutExerciseId: UUID, isWarmup: Bool) async {
        await perform {
            try await self.addSet.execute(workoutExerciseId: workoutExerciseId, isWarmup: isWarmup)
        }
    }

    func removeSet(id: UUID) async {
        await perform {
            try await self.removeSet.execute(setId: id)
        }
    }

    func updateNote(_ text: String) {
        guard let workoutId = workout?.id else {
            return
        }
        noteDraft = text
        publish()
        noteSaveTask?.cancel()
        noteSaveTask = Task { [weak self] in
            do {
                try await Task.sleep(for: Self.noteSaveDelay)
            } catch {
                return
            }
            await self?.saveNote(text, workoutId: workoutId)
        }
    }

    func requestFinish() async {
        guard let workout else {
            return
        }
        if !workout.hasCompletedSets {
            confirmation = .discardEmpty
        } else if workout.incompleteSetCount > 0 {
            confirmation = .finish(incompleteSetCount: workout.incompleteSetCount)
        } else {
            await finish()
            return
        }
        publish()
    }

    func requestCancel() {
        confirmation = .cancel
        publish()
    }

    func confirm(_ confirmation: ActiveWorkoutConfirmation) async {
        self.confirmation = nil
        publish()
        switch confirmation {
        case .finish, .discardEmpty:
            await finish()
        case .cancel:
            noteSaveTask?.cancel()
            await perform {
                try await self.cancelWorkout.execute()
            }
        }
    }

    func dismissConfirmation() {
        confirmation = nil
        publish()
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func apply(_ snapshot: ActiveWorkoutSnapshot) {
        switch snapshot.state {
        case .loading:
            return
        case let .error(error):
            activeWorkoutUiState = .error(error: error)
            return
        case .noWorkout, .active:
            break
        }
        let workout = snapshot.state.workout
        if workout?.id != self.workout?.id {
            resetTransientState()
        }
        self.workout = workout
        rest = snapshot.rest
        hasLoaded = true
        if let editingSetId, workout?.exercise(containingSetId: editingSetId) == nil {
            closeEditor()
        }
        publish()
    }

    private func finish() async {
        noteSaveTask?.cancel()
        if let noteDraft, let workoutId = workout?.id {
            await saveNote(noteDraft, workoutId: workoutId)
        }
        await perform {
            try await self.finishWorkout.execute()
        }
    }

    private func saveNote(_ text: String, workoutId: UUID) async {
        await perform {
            try await self.updateWorkoutNote.execute(workoutId: workoutId, note: text)
        }
    }

    private func perform(_ operation: () async throws -> Void) async {
        do {
            try await operation()
        } catch {
            isShowingError = true
            publish()
        }
    }

    private func editDraft(_ change: (inout SetEntryDraft, ActiveWorkoutExercise) -> Void) {
        guard let editingSetId, var draft = editorDraft, case let (item, _)? = locate(setId: editingSetId) else {
            return
        }
        change(&draft, item)
        editorDraft = draft
        publish()
    }

    private func locate(setId: UUID) -> (item: ActiveWorkoutExercise, entry: SetEntry)? {
        guard let item = workout?.exercise(containingSetId: setId), let entry = item.set(id: setId) else {
            return nil
        }
        return (item: item, entry: entry)
    }

    private func resetTransientState() {
        editingSetId = nil
        editorDraft = nil
        noteDraft = nil
        noteSaveTask?.cancel()
        noteSaveTask = nil
        confirmation = nil
    }

    private func publish() {
        guard hasLoaded else {
            return
        }
        guard let workout else {
            activeWorkoutUiState = .noWorkout
            return
        }
        let editor = editingSetId.flatMap { setId -> SetEditorUiData? in
            guard let editorDraft, case let (item, entry)? = locate(setId: setId) else {
                return nil
            }
            return ActiveWorkoutUiMapper.makeEditor(item: item, entry: entry, draft: editorDraft)
        }
        activeWorkoutUiState = .success(data: ActiveWorkoutUiMapper.makeData(
            workout: workout,
            rest: rest,
            plates: plates,
            note: noteDraft ?? workout.workout.note ?? "",
            editor: editor,
            confirmation: confirmation,
            isShowingError: isShowingError
        ))
    }
}
