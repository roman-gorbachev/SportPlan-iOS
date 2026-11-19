struct ProgramsUiData {
    let exerciseCount: Int
    let programs: [ProgramItem]
    let pendingDeletion: ProgramDeletionConfirmation?
    let pendingDayDeletion: ProgramDayDeletionConfirmation?
    let isShowingError: Bool
}
