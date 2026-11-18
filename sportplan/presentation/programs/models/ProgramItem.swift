import Foundation

struct ProgramItem: Identifiable {
    let id: UUID
    let name: String
    let summary: String
    let days: [ProgramDayItem]
}
