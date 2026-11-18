import SwiftUI

struct RestTimerAccessoryModifier: ViewModifier {
    let viewModel: RestTimerViewModel
    let onOpen: () -> Void

    func body(content: Content) -> some View {
        return Group {
            if #available(iOS 26.1, *) {
                content.tabViewBottomAccessory(isEnabled: restingData != nil) {
                    if let restingData {
                        RestTimerAccessory(
                            data: restingData,
                            onExtend: { Task { await viewModel.extendRest() } },
                            onOpen: onOpen
                        )
                    }
                }
            } else {
                content
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.restFinishedCount)
        .task {
            await viewModel.observe()
        }
    }

    private var restingData: RestTimerItem? {
        guard case let .resting(data) = viewModel.restTimerUiState else {
            return nil
        }
        return data
    }
}
