import Foundation

enum HistoryDayTarget: Hashable {
    case workout(id: UUID)
    case day(date: Date)
}
