import DesignSystem
import SwiftUI

struct ProgramDayScreen: View {
    private static let headerCollapseOffset: CGFloat = 48

    let data: ProgramDayUiData
    let isEditing: Bool
    let onSelectExercise: (UUID) -> Void
    let onAddExercise: () -> Void
    let onEditDay: () -> Void
    let onDelete: (IndexSet) -> Void
    let onMove: (IndexSet, Int) -> Void
    let onDismissError: () -> Void

    @State private var isHeaderScrolledAway = false

    var body: some View {
        return Group {
            if showsEmptyState {
                EmptyStateView(
                    title: String(localized: "programDay.empty.title"),
                    message: String(localized: "programDay.empty.message"),
                    actionTitle: String(localized: "programDay.empty.action"),
                    action: onAddExercise
                )
            } else {
                exerciseList
            }
        }
        .alert(
            String(localized: "common.error.title"),
            isPresented: Binding(get: { return data.isShowingError }, set: { isPresented in
                if !isPresented {
                    onDismissError()
                }
            })
        ) {
            Button(String(localized: "common.ok")) {}
        } message: {
            Text(String(localized: "common.error.message"))
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var showsEmptyState: Bool {
        return data.exercises.isEmpty && !isEditing
    }

    private var navigationTitle: String {
        guard showsEmptyState || isHeaderScrolledAway else {
            return ""
        }
        return data.title
    }

    private var header: some View {
        return Section {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(data.subtitle)
                    .appStyle(Typography.callout)
                    .foregroundStyle(Palette.textSecondary)
                Text(data.title)
                    .appStyle(Typography.largeTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
        .listSectionSeparator(.hidden)
    }

    private var deleteAction: ((IndexSet) -> Void)? {
        guard isEditing else {
            return nil
        }
        return onDelete
    }

    private var moveAction: ((IndexSet, Int) -> Void)? {
        guard isEditing else {
            return nil
        }
        return onMove
    }

    private func removeExercise(id: UUID) {
        guard let index = data.exercises.firstIndex(where: { item in return item.id == id }) else {
            return
        }
        onDelete(IndexSet(integer: index))
    }

    private var exerciseList: some View {
        return List {
            header
            if isEditing {
                Section {
                    NavigationRow(title: String(localized: "programDay.nameAndLabel"), subtitle: data.fullTitle, action: onEditDay)
                }
                .appPlainRow()
            }
            Section {
                ForEach(data.exercises) { item in
                    return Button {
                        onSelectExercise(item.id)
                    } label: {
                        return PlannedExerciseRow(item: item, showsChevron: !isEditing)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEditing)
                    .swipeActions(edge: .trailing) {
                        if !isEditing {
                            DestructiveSwipeButton(title: String(localized: "goals.remove")) {
                                removeExercise(id: item.id)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteAction)
                .onMove(perform: moveAction)
                if !isEditing {
                    Button(action: onAddExercise) {
                        return Label(String(localized: "programDay.addExercise"), systemImage: "plus")
                            .appStyle(Typography.callout)
                    }
                    .foregroundStyle(Palette.accent)
                }
            } footer: {
                Text(isEditing ? String(localized: "programDay.editHint") : String(localized: "programDay.hint"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            .appPlainRow()
        }
        .appPlainList()
        .onScrollGeometryChange(for: Bool.self) { geometry in
            return geometry.contentOffset.y + geometry.contentInsets.top > Self.headerCollapseOffset
        } action: { _, isScrolledAway in
            isHeaderScrolledAway = isScrolledAway
        }
    }
}

#Preview {
    FontRegistry.registerFonts()
    let data = ProgramDayUiData(
        title: "Грудь и трицепс",
        subtitle: "Сила 3× · A",
        fullTitle: "A · Грудь и трицепс",
        exercises: [
            PlannedExerciseRowItem(id: UUID(), name: "Жим лёжа", targetText: "4 × 8–12", targetAccessibilityText: "", detailText: "отдых 2:00 · олимпийский гриф"),
            PlannedExerciseRowItem(id: UUID(), name: "Планка", targetText: "3 подхода", targetAccessibilityText: "", detailText: "на время · отдых 1:00"),
        ],
        isShowingError: false
    )
    return NavigationStack {
        return ProgramDayScreen(
            data: data,
            isEditing: false,
            onSelectExercise: { _ in },
            onAddExercise: {},
            onEditDay: {},
            onDelete: { _ in },
            onMove: { _, _ in },
            onDismissError: {}
        )
    }
}
