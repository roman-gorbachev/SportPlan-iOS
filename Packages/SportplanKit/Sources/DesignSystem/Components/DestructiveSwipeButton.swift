import SwiftUI

public struct DestructiveSwipeButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        return button
            .labelStyle(.iconOnly)
            .tint(Palette.destructive)
            .accessibilityLabel(title)
    }

    @ViewBuilder
    private var button: some View {
        if let systemImage {
            Button(role: .destructive, action: action) {
                return Label(title, systemImage: systemImage)
            }
        } else {
            Button(role: .destructive, action: action)
        }
    }
}
