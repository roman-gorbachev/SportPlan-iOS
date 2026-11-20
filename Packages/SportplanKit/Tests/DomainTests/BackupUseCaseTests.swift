import Domain
import Foundation
import Testing

struct BackupUseCaseTests {
    private static let fileURL = URL(fileURLWithPath: "/backup.json")
    private static let contents = Data("{}".utf8)
    private static let eveningOffset: TimeInterval = 10 * 60 * 60

    private static func makeCandidate() -> BackupCandidate {
        let summary = BackupSummary(exportedAt: DomainFixtures.referenceDate, workoutCount: 3, exerciseCount: 5, programCount: 1)
        return BackupCandidate(summary: summary, contents: contents)
    }

    private static func makeCalendar(timeZone: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: timeZone))
        return calendar
    }

    @Test func exportNamesTheFileByTheLocalDay() async throws {
        let repository = FakeBackupRepository(backup: Self.contents)
        let clock = TestClock()
        clock.advance(by: Self.eveningOffset)
        let calendar = try Self.makeCalendar(timeZone: "Pacific/Kiritimati")
        let export = try await ExportBackupUseCase(repository: repository, now: clock.now, calendar: calendar).execute()
        #expect(export.fileName == "sportplan-2027-01-16.json")
        #expect(export.contents == Self.contents)
        #expect(repository.exportDates == [clock.now()])
    }

    @Test func exportNameUsesTheCalendarTimeZone() async throws {
        let repository = FakeBackupRepository()
        let calendar = try Self.makeCalendar(timeZone: "Pacific/Honolulu")
        let export = try await ExportBackupUseCase(repository: repository, now: TestClock().now, calendar: calendar).execute()
        #expect(export.fileName == "sportplan-2027-01-14.json")
    }

    @Test func readPassesTheCandidateThrough() async throws {
        let candidate = Self.makeCandidate()
        let repository = FakeBackupRepository(readResult: .success(candidate))
        let read = try await ReadBackupUseCase(repository: repository).execute(fileURL: Self.fileURL)
        #expect(read == candidate)
    }

    @Test func readPassesTheErrorThrough() async {
        let repository = FakeBackupRepository(readResult: .failure(.newerVersion))
        await #expect(throws: BackupError.newerVersion) {
            _ = try await ReadBackupUseCase(repository: repository).execute(fileURL: Self.fileURL)
        }
    }

    @Test func importReplacesTheData() async throws {
        let backups = FakeBackupRepository()
        let workouts = FakeWorkoutRepository()
        try await ImportBackupUseCase(backupRepository: backups, workoutRepository: workouts).execute(candidate: Self.makeCandidate())
        #expect(backups.replacedContents == [Self.contents])
    }

    @Test func importIsRejectedDuringAWorkout() async throws {
        let backups = FakeBackupRepository()
        let workouts = FakeWorkoutRepository()
        try await StartEmptyWorkoutUseCase(repository: workouts, now: TestClock().now).execute()
        await #expect(throws: BackupError.workoutInProgress) {
            try await ImportBackupUseCase(backupRepository: backups, workoutRepository: workouts).execute(candidate: Self.makeCandidate())
        }
        #expect(backups.replacedContents.isEmpty)
    }
}
