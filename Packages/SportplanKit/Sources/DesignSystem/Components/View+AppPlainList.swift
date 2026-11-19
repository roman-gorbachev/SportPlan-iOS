import SwiftUI

extension View {
    public func appPlainList() -> some View {
        return listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Palette.background)
    }

    public func appPlainRow() -> some View {
        return listRowBackground(Palette.background)
            .listRowSeparatorTint(Palette.separator)
            .listSectionSeparator(.hidden)
    }
}
