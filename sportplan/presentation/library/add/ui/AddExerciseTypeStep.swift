import DesignSystem
import Domain
import SwiftUI

struct AddExerciseTypeStep: View {
    let viewModel: AddExerciseViewModel
    let onCancel: (() -> Void)?
    let onContinue: () -> Void

    var body: some View {
        return AddExerciseTypeScreen(onSelect: select)
            .navigationTitle(String(localized: "addExercise.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        return Button(String(localized: "common.cancel"), action: onCancel)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    return Text(String(localized: "addExercise.step.first"))
                        .appStyle(Typography.footnote)
                        .foregroundStyle(Palette.textSecondary)
                }
                .sharedBackgroundVisibility(.hidden)
            }
    }

    private func select(_ loadKind: ExerciseLoadKind) {
        viewModel.selectLoadKind(loadKind)
        onContinue()
    }
}
