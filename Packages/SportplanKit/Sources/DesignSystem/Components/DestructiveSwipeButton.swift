import SwiftUI

public struct DestructiveSwipeButton: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        return Button(role: .destructive, action: action) {
            return Label(title, systemImage: systemImage)
                .labelStyle(.iconOnly)
        }
        .tint(Palette.destructive)
        .accessibilityLabel(title)
    }
}
