import Foundation

public struct ExportBackupUseCase: Sendable {
    private static let fileNamePrefix = "sportplan-"
    private static let fileExtension = "json"
    private static let dateFormat = "%04d-%02d-%02d"

    private let repository: any BackupRepository
    private let now: @Sendable () -> Date
    private let calendar: Calendar

    public init(repository: any BackupRepository, now: @escaping @Sendable () -> Date, calendar: Calendar = .current) {
        self.repository = repository
        self.now = now
        self.calendar = calendar
    }

    public func execute() async throws -> BackupExport {
        let date = now()
        let contents = try await repository.makeBackup(exportedAt: date)
        return BackupExport(fileName: fileName(for: date), contents: contents)
    }

    private func fileName(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let day = String(format: Self.dateFormat, components.year ?? 0, components.month ?? 0, components.day ?? 0)
        return "\(Self.fileNamePrefix)\(day).\(Self.fileExtension)"
    }
}
