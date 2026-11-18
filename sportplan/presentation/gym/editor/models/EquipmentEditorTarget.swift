import Domain
import Foundation

enum EquipmentEditorTarget: Hashable, Identifiable {
    case new(kind: EquipmentKind)
    case existing(id: UUID)

    var id: Self {
        return self
    }
}
