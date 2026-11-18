import Domain
import Foundation
import Observation

@Observable
final class ProgramDayFormViewModel {
    @ObservationIgnored private let target: ProgramDayFormTarget
    @ObservationIgnored private let addProgramDay: AddProgramDayUseCase
    @ObservationIgnored private let updateProgramDay: UpdateProgramDayUseCase
    @ObservationIgnored private let deleteProgramDay: DeleteProgramDayUseCase
    @ObservationIgnored private var draft: ProgramDayDraft
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var isConfirmingDelete = false
    @ObservationIgnored private var isShowingError = false

    private(set) var dayFormUiState: ProgramDayFormUiState = .loading

    init(
        target: ProgramDayFormTarget,
        addProgramDay: AddProgramDayUseCase,
        updateProgramDay: UpdateProgramDayUseCase,
        deleteProgramDay: DeleteProgramDayUseCase
    ) {
        self.target = target
        self.addProgramDay = addProgramDay
        self.updateProgramDay = updateProgramDay
        self.deleteProgramDay = deleteProgramDay
        switch target {
        case .new:
            draft = ProgramDayDraft()
        case let .edit(day, _):
            draft = ProgramDayDraft(day: day)
        }
        publish()
    }

    func updateLabel(_ label: String) {
        draft.label = label
        publish()
    }

    func updateName(_ name: String) {
        draft.name = name
        publish()
    }

    func save() async -> Bool {
        guard !isSaving, draft.isValid else {
            return false
        }
        isSaving = true
        publish()
        do {
            switch target {
            case let .new(programId, _):
                _ = try await addProgramDay.execute(programId: programId, draft: draft)
            case let .edit(day, _):
                try await updateProgramDay.execute(id: day.id, draft: draft)
            }
            return true
        } catch {
            isSaving = false
            isShowingError = true
            publish()
            return false
        }
    }

    func requestDelete() {
        isConfirmingDelete = true
        publish()
    }

    func cancelDelete() {
        isConfirmingDelete = false
        publish()
    }

    func confirmDelete() async -> Bool {
        isConfirmingDelete = false
        publish()
        guard case let .edit(day, _) = target else {
            return false
        }
        do {
            try await deleteProgramDay.execute(id: day.id)
            return true
        } catch {
            isShowingError = true
            publish()
            return false
        }
    }

    func dismissError() {
        isShowingError = false
        publish()
    }

    private func publish() {
        let programName: String
        let originalName: String
        let isNew: Bool
        switch target {
        case let .new(_, name):
            programName = name
            originalName = ""
            isNew = true
        case let .edit(day, name):
            programName = name
            originalName = day.name
            isNew = false
        }
        dayFormUiState = .success(data: ProgramDayFormUiData(
            isNew: isNew,
            programName: programName,
            label: draft.label,
            name: draft.name,
            originalName: originalName,
            canSave: !isSaving && draft.isValid,
            isConfirmingDelete: isConfirmingDelete,
            isShowingError: isShowingError
        ))
    }
}
