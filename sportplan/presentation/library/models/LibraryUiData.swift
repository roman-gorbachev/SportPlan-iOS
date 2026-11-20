struct LibraryUiData {
    let sections: [LibrarySectionItem]
    let isLibraryEmpty: Bool
    let searchQuery: String
    let archivedCount: Int
    let pendingArchive: LibraryArchiveConfirmation?
    let isShowingArchiveError: Bool
}
