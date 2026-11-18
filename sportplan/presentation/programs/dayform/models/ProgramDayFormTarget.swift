import Domain
import Foundation

enum ProgramDayFormTarget: Hashable, Identifiable {
    case new(programId: UUID, programName: String)
    case edit(day: ProgramDay, programName: String)

    var id: Self {
        return self
    }
}
