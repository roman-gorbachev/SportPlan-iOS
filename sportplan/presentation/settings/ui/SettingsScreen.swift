import DesignSystem
import Domain
import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
    let data: SettingsUiData
    let exportItem: BackupExportItem
    let onOpenGym: () -> Void
    let onImportFile: (URL) -> Void
    let onImportFileFailed: () -> Void
    let onConfirmImport: () -> Void
    let onCancelImport: () -> Void
    let onDismissImportResult: () -> Void

    @State private var isImporterPresented = false

    var body: some View {
        return List {
            Section {
                NavigationRow(title: String(localized: "settings.gym.title"), subtitle: equipmentSummary, action: onOpenGym)
                    .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "settings.section.gym"))
            }
            Section {
                ShareLink(item: exportItem, preview: SharePreview(String(localized: "settings.data.exportPreview"))) {
                    return SettingsActionLabel(
                        title: String(localized: "settings.data.export"),
                        systemImage: "square.and.arrow.up",
                        isEnabled: true
                    )
                }
                .buttonStyle(.plain)
                .appListRow()
                Button {
                    isImporterPresented = true
                } label: {
                    return SettingsActionLabel(
                        title: String(localized: "settings.data.import"),
                        systemImage: "square.and.arrow.down",
                        isEnabled: isImportEnabled
                    )
                }
                .buttonStyle(.plain)
                .disabled(!isImportEnabled)
                .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "settings.section.data"))
            } footer: {
                Text(data.isImportAvailable ? String(localized: "settings.data.footer") : String(localized: "settings.data.importBlocked"))
                    .appStyle(Typography.footnote)
                    .foregroundStyle(Palette.textSecondary)
            }
            Section {
                LabeledContent(String(localized: "settings.version"), value: data.appVersion)
                    .appStyle(Typography.body)
                    .foregroundStyle(Palette.textPrimary)
                    .appListRow()
            } header: {
                ListSectionHeader(title: String(localized: "settings.section.about"))
            }
        }
        .appGroupedList()
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.json]) { result in
            switch result {
            case let .success(url):
                onImportFile(url)
            case .failure:
                onImportFileFailed()
            }
        }
        .alert(
            String(localized: "settings.data.confirm.title"),
            isPresented: Binding(get: { return confirmationMessage != nil }, set: { _ in }),
            presenting: confirmationMessage
        ) { _ in
            Button(String(localized: "common.cancel"), role: .cancel, action: onCancelImport)
            Button(String(localized: "settings.data.confirm.replace"), role: .destructive, action: onConfirmImport)
        } message: { message in
            return Text(message)
        }
        .alert(
            String(localized: "settings.data.finished.title"),
            isPresented: Binding(get: { return data.importStep == .finished }, set: { _ in })
        ) {
            Button(String(localized: "common.ok"), action: onDismissImportResult)
        }
        .alert(
            String(localized: "settings.data.failed.title"),
            isPresented: Binding(get: { return failureMessage != nil }, set: { _ in }),
            presenting: failureMessage
        ) { _ in
            Button(String(localized: "common.ok"), action: onDismissImportResult)
        } message: { message in
            return Text(message)
        }
    }

    private var isImportEnabled: Bool {
        return data.isImportAvailable && data.importStep == .idle
    }

    private var confirmationMessage: String? {
        guard case let .confirming(message) = data.importStep else {
            return nil
        }
        return message
    }

    private var failureMessage: String? {
        guard case let .failed(message) = data.importStep else {
            return nil
        }
        return message
    }

    private var equipmentSummary: String {
        let equipmentText = data.equipmentCount > 0
            ? String(localized: "settings.gym.equipmentCount \(data.equipmentCount)")
            : String(localized: "settings.gym.empty")
        guard data.plateCount > 0 else {
            return equipmentText
        }
        return String(localized: "settings.gym.summary \(equipmentText) \(String(localized: "settings.gym.plateCount \(data.plateCount)"))")
    }
}

#Preview {
    FontRegistry.registerFonts()
    return NavigationStack {
        return SettingsScreen(
            data: SettingsUiData(equipmentCount: 6, plateCount: 7, appVersion: "1.0", isImportAvailable: true, importStep: .idle),
            exportItem: BackupExportItem(makeExport: { return BackupExport(fileName: "sportplan.json", contents: Data()) }),
            onOpenGym: {},
            onImportFile: { _ in },
            onImportFileFailed: {},
            onConfirmImport: {},
            onCancelImport: {},
            onDismissImportResult: {}
        )
        .navigationTitle(String(localized: "settings.title"))
    }
}

#Preview("Во время тренировки") {
    FontRegistry.registerFonts()
    return NavigationStack {
        return SettingsScreen(
            data: SettingsUiData(equipmentCount: 6, plateCount: 7, appVersion: "1.0", isImportAvailable: false, importStep: .idle),
            exportItem: BackupExportItem(makeExport: { return BackupExport(fileName: "sportplan.json", contents: Data()) }),
            onOpenGym: {},
            onImportFile: { _ in },
            onImportFileFailed: {},
            onConfirmImport: {},
            onCancelImport: {},
            onDismissImportResult: {}
        )
        .navigationTitle(String(localized: "settings.title"))
    }
}
