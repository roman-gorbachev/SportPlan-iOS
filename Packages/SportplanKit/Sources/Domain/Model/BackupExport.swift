import Foundation

public struct BackupExport: Equatable, Sendable {
    public let fileName: String
    public let contents: Data

    public init(fileName: String, contents: Data) {
        self.fileName = fileName
        self.contents = contents
    }
}
