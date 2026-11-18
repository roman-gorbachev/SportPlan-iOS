import SwiftUI

extension View {
    public func appGroupedList() -> some View {
        return scrollContentBackground(.hidden)
            .background(Palette.background)
    }

    public func appListRow() -> some View {
        return listRowBackground(Palette.surface)
            .listRowSeparatorTint(Palette.separator)
    }
}
