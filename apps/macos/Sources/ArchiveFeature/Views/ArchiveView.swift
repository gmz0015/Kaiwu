import AppKit
import KaiwuCore
import KaiwuUI
import SwiftUI

struct ArchiveView: View {
    let service: any ArchiveServicing
    let libraryService: ArchiveLibraryService
    @AppStorage(ArchivePreset.preferenceKey) private var preset = ArchivePreset.standard
    @AppStorage(ArchiveLibraryService.historyEnabledKey) private var keepHistory = true
    @State private var source: URL?
    @State private var operation = ToolTask<ArchiveReceipt>()
    @State private var libraryOperation = ToolTask<URL?>()
    @State private var progress: ArchiveProgress?
    @State private var library = ArchiveLibrary()
    @State private var libraryError: String?

    var body: some View {
        FeaturePage("目录打包", subtitle: "选择目录，导出便于分享的 ZIP。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label(source?.path ?? "尚未选择目录", systemImage: "folder")
                        .lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                    HStack {
                        Button("选择目录…") {
                            if let chosen = FilePanels.directory() { select(chosen) }
                        }
                        Button("保存书签") {
                            guard let source else { return }
                            libraryAction {
                                library = try await libraryService.addBookmark(source); return nil
                            }
                        }.disabled(source == nil)
                    }.disabled(busy)
                    Picker("打包规则", selection: $preset) {
                        ForEach(ArchivePreset.allCases, id: \.self) { Text($0.title).tag($0) }
                    }.pickerStyle(.segmented).disabled(operation.isRunning)
                    Text("自动排除 macOS 元数据，跳过符号链接。" + preset.detail)
                        .font(.callout).foregroundStyle(.secondary)
                    Text("需要额外磁盘空间保存暂存副本。离开页面会取消尚未完成的打包。")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("导出 ZIP…", action: export).buttonStyle(.borderedProminent)
                            .keyboardShortcut("e", modifiers: [.command, .shift])
                            .disabled(source == nil || busy)
                        if operation.isRunning {
                            ToolTaskControls(isCancelling: operation.isCancelling, cancel: operation.cancel)
                        }
                    }
                    if operation.isRunning, let progress { ArchiveProgressView(progress: progress) }
                }.padding(12)
            }
            if let receipt = operation.result {
                Label("已打包 \(receipt.fileCount) 个文件，跳过 \(receipt.skippedCount) 个条目。", systemImage: "checkmark.circle")
                Button("在 Finder 中显示") { NSWorkspace.shared.activateFileViewerSelecting([receipt.destination]) }
            }
            if let error = operation.error { Text(error).foregroundStyle(.red) }
            if let error = libraryOperation.error ?? libraryError { Text(error).foregroundStyle(.red) }
            librarySection
        }
        .task { await reloadLibrary() }
        .onDisappear {
            operation.cancel(); libraryOperation.cancel()
        }
    }

    private var busy: Bool { operation.isRunning || libraryOperation.isRunning }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !library.bookmarks.isEmpty {
                GroupBox("常用目录") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(library.bookmarks) { bookmark in
                            HStack {
                                Button {
                                    libraryAction { try await libraryService.resolveBookmark(bookmark.id) }
                                } label: {
                                    Label(bookmark.name, systemImage: "folder.badge.person.crop")
                                }
                                Spacer()
                                Button("移除") {
                                    libraryAction {
                                        library = try await libraryService.removeBookmark(bookmark.id); return nil
                                    }
                                }.accessibilityLabel("移除书签：" + bookmark.name)
                            }
                        }
                    }.padding(8).disabled(busy)
                }
            }
            GroupBox("最近打包") {
                VStack(alignment: .leading, spacing: 12) {
                    if library.history.isEmpty {
                        Text(keepHistory ? "成功导出后，这里保留最近 20 条记录。" : "记录已关闭，可在设置中开启。")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(library.history) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.destinationName).lineLimit(1)
                                Text(
                                    "\(item.date.formatted(date: .abbreviated, time: .shortened)) · \(item.fileCount) 个文件 · \(item.preset.title)"
                                )
                                .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("再次打包") {
                                libraryAction {
                                    let url = try await libraryService.resolveHistory(item.id, source: true)
                                    preset = item.preset
                                    return url
                                }
                            }
                            Button("显示文件") {
                                libraryAction {
                                    let url = try await libraryService.resolveHistory(item.id, source: false)
                                    NSWorkspace.shared.activateFileViewerSelecting([url])
                                    return nil
                                }
                            }
                        }
                    }
                    if !library.history.isEmpty {
                        Button("清除历史") {
                            libraryAction {
                                library = try await libraryService.clearHistory(); return nil
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(8).disabled(busy)
            }
        }
    }

    private func select(_ url: URL) { source = url; operation.clear(); libraryError = nil }

    private func libraryAction(_ action: @escaping @MainActor @Sendable () async throws -> URL?) {
        libraryError = nil
        libraryOperation.start {
            let url = try await action()
            try Task.checkCancellation()
            if let url { select(url) }
            return url
        }
    }

    private func reloadLibrary() async {
        do { library = try await libraryService.load(); libraryError = nil } catch {
            libraryError = error.localizedDescription
        }
    }

    private func export() {
        guard let source, let destination = FilePanels.archive(named: source.lastPathComponent) else { return }
        let selectedPreset = preset
        let recordHistory = keepHistory
        progress = .init(phase: .scanning)
        libraryError = nil
        operation.start {
            let receipt = try await service.create(
                .init(source: source, destination: destination, policy: selectedPreset.policy)
            ) { update in
                await MainActor.run { progress = update }
            }
            if recordHistory {
                do {
                    library = try await libraryService.remember(
                        source: source, receipt: receipt, preset: selectedPreset)
                } catch { libraryError = "ZIP 已保存，但历史记录保存失败：" + error.localizedDescription }
            }
            return receipt
        }
    }
}
