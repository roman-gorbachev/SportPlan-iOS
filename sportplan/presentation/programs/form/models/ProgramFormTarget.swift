import Foundation

enum ProgramFormTarget: Hashable, Identifiable {
    case create
    case rename(id: UUID, name: String)

    var id: Self {
        return self
    }
}
