import Domain
import Foundation
import Testing

struct RestPeriodTests {
    private static let start = DomainFixtures.referenceDate

    @Test func durationAndActivityFollowTheEndDate() {
        let rest = RestPeriod(startedAt: Self.start, seconds: 120)
        #expect(rest.duration == 120)
        #expect(rest.isActive(at: Self.start.addingTimeInterval(119)))
        #expect(!rest.isActive(at: Self.start.addingTimeInterval(120)))
        #expect(rest.remaining(at: Self.start.addingTimeInterval(30)) == 90)
        #expect(rest.remaining(at: Self.start.addingTimeInterval(200)) == 0)
    }

    @Test func adjustingMovesOnlyTheEnd() throws {
        let rest = RestPeriod(startedAt: Self.start, seconds: 120)
        let now = Self.start.addingTimeInterval(30)
        let longer = try #require(rest.adjusted(bySeconds: 15, now: now))
        #expect(longer.startedAt == Self.start)
        #expect(longer.duration == 135)
        let shorter = try #require(rest.adjusted(bySeconds: -15, now: now))
        #expect(shorter.duration == 105)
    }

    @Test func shorteningPastNowEndsTheRest() {
        let rest = RestPeriod(startedAt: Self.start, seconds: 120)
        #expect(rest.adjusted(bySeconds: -15, now: Self.start.addingTimeInterval(105)) == nil)
        #expect(rest.adjusted(bySeconds: -15, now: Self.start.addingTimeInterval(110)) == nil)
    }
}
