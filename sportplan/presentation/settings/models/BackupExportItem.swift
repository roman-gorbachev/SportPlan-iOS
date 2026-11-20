import CoreTransferable
import Domain
import Foundation
import UniformTypeIdentifiers

nonisolated struct BackupExportItem: Transferable {
    let makeExport: @Sendable () async throws -> BackupExport

    static var transferRepresentation: some TransferRepresentation {
        return FileRepresentation(exportedContentType: .json) { (item: BackupExportItem) async throws -> SentTransferredFile in
            let export = try await item.makeExport()
            let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let fileURL = directory.appending(path: export.fileName, directoryHint: .notDirectory)
            try export.contents.write(to: fileURL, options: .atomic)
            return SentTransferredFile(fileURL)
        }
    }
}
