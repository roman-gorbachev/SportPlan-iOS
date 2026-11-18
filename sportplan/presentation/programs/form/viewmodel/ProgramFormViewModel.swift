import Domain
import Foundation
import Observation

@Observable
final class ProgramFormViewModel {
    @ObservationIgnored private let target: ProgramFormTarget
    @ObservationIgnored private let createProgram: CreateProgramUseCase
    @ObservationIgnored private let renameProgram: RenameProgramUseCase
    @ObservationIgnored private var programDraft: ProgramDraft
    @ObservationIgnored private var dayDraft = ProgramDayDraft()
    @ObservationIgnored private var isSaving = false
    @ObservationIgnored private var isShowingSaveError = false

    private(set) var programFormUiState: ProgramFormUiState = .loading

    init(target: ProgramFormTarget, createProgram: CreateProgramUseCase, renameProgram: RenameProgramUseCase) {
        self.target = target
        self.createProgram = createProgram
        self.renameProgram = renameProgram
        switch target {
        case .create:
            programDraft = ProgramDraft()
        case let .rename(_, name):
            programDraft = ProgramDraft(name: name)
        }
        publish()
    }

    func updateName(_ name: String) {
        programDraft.name = name
        publish()
    }

    func updateDayLabel(_ label: String) {
        dayDraft.label = label
        publish()
    }

    func updateDayName(_ name: String) {
        dayDraft.name = name
        publish()
    }

    func dismissSaveError() {
        isShowingSaveError = false
        publish()
    }

    func save() async -> Bool {
        guard !isSaving, isValid else {
            return false
        }
        isSaving = true
        publish()
        do {
            switch target {
            case .create:
                _ = try await createProgram.execute(program: programDraft, firstDay: dayDraft)
            case let .rename(id, _):
                try await renameProgram.execute(id: id, draft: programDraft)
            }
            return true
        } catch {
            isSaving = false
            isShowingSaveError = true
            publish()
            return false
        }
    }

    private var isCreating: Bool {
        return target == .create
    }

    private var isValid: Bool {
        guard isCreating else {
            return programDraft.isValid
        }
        return programDraft.isValid && dayDraft.isValid
    }

    private func publish() {
        programFormUiState = .success(data: ProgramFormUiData(
            isCreating: isCreating,
            name: programDraft.name,
            dayLabel: dayDraft.label,
            dayName: dayDraft.name,
            canSave: !isSaving && isValid,
            isShowingSaveError: isShowingSaveError
        ))
    }
}
