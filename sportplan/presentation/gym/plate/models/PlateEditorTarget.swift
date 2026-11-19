import Foundation

enum PlateEditorTarget: Hashable, Identifiable {
    case new
    case existing(id: UUID)

    var id: Self {
        return self
    }
}
