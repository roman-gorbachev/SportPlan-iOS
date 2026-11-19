import Domain
import SwiftUI

struct GymRoute: View {
    private static let newEquipmentKind: EquipmentKind = .barbell

    @State private var viewModel: GymViewModel
    @State private var editorTarget: EquipmentEditorTarget?
    @State private var plateEditorTarget: PlateEditorTarget?
    private let makeEditorViewModel: (EquipmentEditorTarget) -> EquipmentEditorViewModel
    private let makePlateEditorViewModel: (PlateEditorTarget) -> PlateEditorViewModel

    init(
        viewModel: GymViewModel,
        makeEditorViewModel: @escaping (EquipmentEditorTarget) -> EquipmentEditorViewModel,
        makePlateEditorViewModel: @escaping (PlateEditorTarget) -> PlateEditorViewModel
    ) {
        _viewModel = State(initialValue: viewModel)
        self.makeEditorViewModel = makeEditorViewModel
        self.makePlateEditorViewModel = makePlateEditorViewModel
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
                    onSelect: { id in editorTarget = .existing(id: id) },
                    onAddPlate: { plateEditorTarget = .new },
                    onSelectPlate: { id in plateEditorTarget = .existing(id: id) },
                    onResetPlates: { Task { await viewModel.resetPlates() } },
                    onDismissResetError: viewModel.dismissResetError
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
        .sheet(item: $plateEditorTarget) { target in
            return PlateEditorRoute(
                viewModel: makePlateEditorViewModel(target),
                onClose: { plateEditorTarget = nil }
            )
        }
    }
}
