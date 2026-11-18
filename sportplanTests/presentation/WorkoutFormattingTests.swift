import Foundation
import Testing
@testable import sportplan

struct WorkoutFormattingTests {
    private static let year = 2026
    private static let month = 11
    private static let monday = 16
    private static let noon = 12

    @Test func shortDateIsLowercaseWeekdayWithDayAndMonth() throws {
        let components = DateComponents(year: Self.year, month: Self.month, day: Self.monday, hour: Self.noon)
        let date = try #require(Calendar.current.date(from: components))
        #expect(WorkoutFormatting.shortDate(date) == "пн 16.11")
    }
}
