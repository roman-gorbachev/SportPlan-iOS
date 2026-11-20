import Foundation

public struct BackupCandidate: Equatable, Sendable {
    public let summary: BackupSummary
    public let contents: Data

    public init(summary: BackupSummary, contents: Data) {
        self.summary = summary
        self.contents = contents
    }
}
