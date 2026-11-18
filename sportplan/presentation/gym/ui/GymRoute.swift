import Domain
import SwiftUI

struct GymRoute: View {
    private static let newEquipmentKind: EquipmentKind = .barbell

    @State private var viewModel: GymViewModel
    @State private var editorTarget: EquipmentEditorTarget?
    private let makeEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel

    init(viewModel: GymViewModel, makeEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel) {
        _viewModel = State(initialValue: viewModel)
        self.makeEditorViewModel = makeEditorViewModel
    }

    var body: some View {
        return Group {
            switch viewModel.gymUiState {
            case .loading:
                LoadingStateView()
            case let .success(data):
                GymScreen(
                    data: data,
                    onAdd: { editorTarget = .new(kind: Self.newEquipmentKind) },
                    onSelect: { id in editorTarget = .existing(id: id) }
                )
            case .error:
                ErrorStateView()
            }
        }
        .navigationTitle(String(localized: "gym.title"))
        .task {
            await viewModel.observe()
        }
        .sheet(item: $editorTarget) { target in
            return EquipmentEditorRoute(
                viewModel: makeEditorViewModel(target),
                onSaved: { _ in },
                onClose: { editorTarget = nil }
            )
        }
    }
}
