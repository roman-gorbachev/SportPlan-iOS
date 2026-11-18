import SwiftUI

public struct EmptyStateView: View {
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        return VStack(spacing: Spacing.s) {
            Text(title)
                .appStyle(Typography.title)
                .foregroundStyle(Palette.textPrimary)
            Text(message)
                .appStyle(Typography.body)
                .foregroundStyle(Palette.textSecondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(InkButtonStyle())
                    .padding(.top, Spacing.m)
            }
        }
        .multilineTextAlignment(.center)
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
    }
}
